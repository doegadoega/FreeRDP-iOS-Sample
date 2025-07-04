//
//  FreeRDPBridge.m
//  MyRDPApp
//
//  Created on 2025/05/23.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

#import "FreeRDPBridge.h"
#import <CoreGraphics/CoreGraphics.h>
#import <netdb.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import "OpenSSLHelper.h"

// FreeRDPヘッダーのインポート
#include <freerdp/freerdp.h>
#include <freerdp/client.h>
#include <freerdp/gdi/gdi.h>
#include <freerdp/client/cmdline.h>
#include <freerdp/input.h>
#include <winpr/stream.h>
#include <winpr/wlog.h>
#include <winpr/synch.h>
// FreeRDP用のコンテキスト構造体
typedef struct {
    rdpContext context;  // 最初のメンバーとしてrdpContextを配置
    
    // 画面更新のための状態
    BOOL hasUpdates;
    CGContextRef drawContext;
    CRITICAL_SECTION updateLock;
    
    // ブリッジへの参照（コールバックで使用）
    __unsafe_unretained FreeRDPBridge* bridge;
} MyRdpContext;

// FreeRDPコールバック関数のプロトタイプ宣言
static BOOL rdp_pre_connect(freerdp* instance);
static BOOL rdp_post_connect(freerdp* instance);
static void rdp_post_disconnect(freerdp* instance);
static BOOL rdp_authenticate(freerdp* instance, char** username, char** password, char** domain);
static DWORD rdp_verify_certificate_ex(freerdp* instance, const char* host, UINT16 port,
                                       const char* common_name, const char* subject,
                                       const char* issuer, const char* fingerprint,
                                       DWORD flags);
static DWORD rdp_verify_changed_certificate_ex(freerdp* instance, const char* host, UINT16 port,
                                               const char* common_name, const char* subject,
                                               const char* issuer, const char* fingerprint,
                                               const char* old_subject, const char* old_issuer,
                                               const char* old_fingerprint, DWORD flags);

// 画面更新コールバック
static BOOL context_new(freerdp* instance, rdpContext* context);
static void context_free(freerdp* instance, rdpContext* context);
static BOOL gdi_begin_paint(rdpContext* context);
static BOOL gdi_end_paint(rdpContext* context);

@interface FreeRDPBridge ()

// プライベートプロパティ
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL isConnecting;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) int32_t port;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *domain;
    
// 画面サイズと設定
@property (nonatomic, assign) CGSize screenSize;
@property (nonatomic, assign) int32_t colorDepth;
@property (nonatomic, assign) BOOL compressionEnabled;
@property (nonatomic, assign) int32_t securityLevel;
    
// スレッド関連
@property (nonatomic, strong) NSThread *rdpThread;
@property (nonatomic, strong) NSCondition *connectionCondition;
@property (nonatomic, strong) NSTimer *updateTimer;

// 画面バッファ
@property (nonatomic, assign) CGContextRef cgContext;
@property (nonatomic, assign) CGImageRef lastImage;
@property (atomic, assign) BOOL hasUpdates;

// コールバックブロック
@property (nonatomic, copy) void (^onConnectionStateChangedBlock)(BOOL);
@property (nonatomic, copy) void (^onErrorBlock)(NSString *);
@property (nonatomic, copy) void (^onScreenUpdateBlock)(CGImageRef);

// FreeRDPコンテキスト
@property (nonatomic, assign) freerdp* rdpInstance;
@property (nonatomic, assign) MyRdpContext* rdpContext;

@end

@implementation FreeRDPBridge

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static FreeRDPBridge *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"FreeRDPBridge initialized");
        
        // OpenSSLの初期化（重要！）
        [OpenSSLHelper initializeOpenSSL];
        [OpenSSLHelper forceMD4Registration];
        
        // MD4が利用可能か確認
        if ([OpenSSLHelper isMD4Available]) {
            NSLog(@"✓ MD4 is available in FreeRDP context");
        } else {
            NSLog(@"✗ MD4 is NOT available in FreeRDP context");
        }
                
        _screenSize = CGSizeMake(1024, 768);
        _colorDepth = 32;
        _compressionEnabled = YES;
        _securityLevel = 1;
        _isConnected = NO;
        _isConnecting = NO;
        _hasUpdates = NO;
        
        _connectionCondition = [[NSCondition alloc] init];
        
        WLog_SetLogLevel(WLog_GetRoot(), WLOG_INFO);
    }
    return self;
}

- (void)dealloc {
    [self disconnect];
    [self cleanup];
}

- (void)cleanup {
    [self stopUpdateTimer];
    
    if (_cgContext) {
        CGContextRelease(_cgContext);
        _cgContext = NULL;
    }
    
    if (_lastImage) {
        CGImageRelease(_lastImage);
        _lastImage = NULL;
    }
    
    // FreeRDPのリソース解放
    if (_rdpInstance) {
        freerdp_disconnect(_rdpInstance);
        freerdp_free(_rdpInstance);
        _rdpInstance = NULL;
    }
    
    _rdpContext = NULL;
}

#pragma mark - Callback Setters

- (void)setOnConnectionStateChanged:(void (^)(BOOL))block {
    _onConnectionStateChangedBlock = block;
}

- (void)setOnError:(void (^)(NSString *))block {
    _onErrorBlock = block;
}

- (void)setOnScreenUpdate:(void (^)(CGImageRef))block {
    _onScreenUpdateBlock = block;
}

#pragma mark - Connection Management

- (void)disconnect {
    if (!_isConnected && !_isConnecting) {
        return;
    }
    
    NSLog(@"Disconnecting from RDP session");
    
    // タイマーを停止
    [self stopUpdateTimer];
    
    // 実際のRDP接続がある場合は切断
    if (_rdpInstance) {
        freerdp_abort_connect(_rdpInstance);
        freerdp_disconnect(_rdpInstance);
    }
    
    _isConnected = NO;
    _isConnecting = NO;
    
    // 切断通知
    if (_onConnectionStateChangedBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_onConnectionStateChangedBlock(NO);
        });
    }
}

- (BOOL)connectToHost:(NSString *)host
                 port:(int32_t)port
             username:(NSString *)username
             password:(NSString *)password
               domain:(NSString *)domain {
    
    if (_isConnected || _isConnecting) {
        NSLog(@"Already connected or connecting");
        return NO;
    }
    
    // 接続パラメータの保存
    _host = [host copy];
    _port = port;
    _username = [username copy];
    _password = [password copy];
    
    // ドメインはデフォルトで空文字列に設定（ローカルログイン）
    _domain = @""; // ドメインは指定しない（未指定としても問題ないようにする）
    
    _isConnecting = YES;
    
    NSLog(@"Connecting to %@:%d as %@ (domain: '%@')", host, port, username, domain ? domain : @"未指定");
    NSLog(@"テスト中のポート番号: %d （標準RDPポートは3389）", port);
    
    // 接続スレッドの開始
    _rdpThread = [[NSThread alloc] initWithTarget:self selector:@selector(rdpThreadMain) object:nil];
    [_rdpThread start];
    
    return YES;
}

- (void)rdpThreadMain {
    @autoreleasepool {
        NSLog(@"RDP thread started");
        
        // ネットワーク接続テスト
        BOOL networkReachable = [self testNetworkConnection];
        
        if (!networkReachable) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyError:[NSString stringWithFormat:@"ホスト %@ に接続できません", self->_host]];
                self->_isConnecting = NO;
            });
            return;
        }
        
        // FreeRDPインスタンスの初期化と設定
        BOOL initResult = [self initializeRDPInstance];
        if (!initResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyError:@"FreeRDPの初期化に失敗しました"];
                self->_isConnecting = NO;
            });
            return;
        }
        
        // RDP接続の開始
        BOOL connected = [self connectWithRDP];
        
        if (connected) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_isConnected = YES;
                self->_isConnecting = NO;
                
                NSLog(@"RDP connection established successfully");
                
                if (self->_onConnectionStateChangedBlock) {
                    self->_onConnectionStateChangedBlock(YES);
                }
                
                // 画面更新タイマーを開始
                [self startUpdateTimer];
            });
            
            // メインループ - FreeRDPのイベント処理
            [self runRDPMainLoop];
            
            // 接続終了処理
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_isConnected = NO;
                if (self->_onConnectionStateChangedBlock) {
                    self->_onConnectionStateChangedBlock(NO);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_isConnecting = NO;
                [self notifyError:@"RDP接続に失敗しました"];
            });
        }
    }
}

// FreeRDPインスタンスの初期化
- (BOOL)initializeRDPInstance {
    // FreeRDPインスタンスの作成
    _rdpInstance = freerdp_new();
    if (!_rdpInstance) {
        NSLog(@"Failed to create FreeRDP instance");
        return NO;
    }
    
    // コンテキストサイズとコールバックの設定
    _rdpInstance->ContextSize = sizeof(MyRdpContext);
    _rdpInstance->ContextNew = context_new;
    _rdpInstance->ContextFree = context_free;
    
    // 接続コールバックの設定
    _rdpInstance->PreConnect = rdp_pre_connect;
    _rdpInstance->PostConnect = rdp_post_connect;
    _rdpInstance->PostDisconnect = rdp_post_disconnect;
    _rdpInstance->Authenticate = rdp_authenticate;
    _rdpInstance->VerifyCertificateEx = rdp_verify_certificate_ex;
    _rdpInstance->VerifyChangedCertificateEx = rdp_verify_changed_certificate_ex;
    
    // コンテキストの初期化
    if (!freerdp_context_new(_rdpInstance)) {
        NSLog(@"Failed to initialize FreeRDP context");
        freerdp_free(_rdpInstance);
        _rdpInstance = NULL;
        return NO;
    }
    
    _rdpContext = (MyRdpContext*)_rdpInstance->context;
    _rdpContext->bridge = self;
    
    // 設定の初期化
    rdpSettings* settings = _rdpInstance->context->settings;
    
    // 接続パラメータの設定
    if (!freerdp_settings_set_string(settings, FreeRDP_ServerHostname, [_host UTF8String])) {
        NSLog(@"Failed to set hostname");
        return NO;
    }
    
    NSLog(@"ホスト名設定: %@", _host);
    
    freerdp_settings_set_uint32(settings, FreeRDP_ServerPort, _port);
    NSLog(@"ポート設定: %d", _port);
    
    if (_username) {
        freerdp_settings_set_string(settings, FreeRDP_Username, [_username UTF8String]);
        NSLog(@"ユーザー名設定: %@", _username);
    }
    if (_password) {
        freerdp_settings_set_string(settings, FreeRDP_Password, [_password UTF8String]);
        NSLog(@"パスワード設定: (セキュリティのため非表示)");
    }
    
    // ドメインは空文字列を設定（必須項目）
    freerdp_settings_set_string(settings, FreeRDP_Domain, "");
    NSLog(@"ドメイン設定: ''（空）");
    
    // 画面設定
    freerdp_settings_set_uint32(settings, FreeRDP_DesktopWidth, (UINT32)_screenSize.width);
    freerdp_settings_set_uint32(settings, FreeRDP_DesktopHeight, (UINT32)_screenSize.height);
    freerdp_settings_set_uint32(settings, FreeRDP_ColorDepth, _colorDepth);
    NSLog(@"画面設定: %d x %d, %dビット", (int)_screenSize.width, (int)_screenSize.height, _colorDepth);
    
    // セキュリティ設定 - Hybrid認証を許可
//    // EC2インスタンスはHYBRID_REQUIRED_BY_SERVERエラーが出るため、NLAを有効にする
//    freerdp_settings_set_bool(settings, FreeRDP_NlaSecurity, TRUE);
//    freerdp_settings_set_bool(settings, FreeRDP_TlsSecurity, TRUE);
//    freerdp_settings_set_bool(settings, FreeRDP_RdpSecurity, TRUE);
//    freerdp_settings_set_bool(settings, FreeRDP_IgnoreCertificate, TRUE);
//    // NLAに必要なOpenSSLレガシープロバイダを強制的に有効化
//    freerdp_settings_set_bool(settings, FreeRDP_UseRdpSecurityLayer, FALSE);
//    // 設定項目の型修正
//    freerdp_settings_set_bool(settings, FreeRDP_OffscreenSupportLevel, TRUE);
//    freerdp_settings_set_bool(settings, FreeRDP_FastPathInput, TRUE);
//    freerdp_settings_set_bool(settings, FreeRDP_FastPathOutput, TRUE);

    // セキュリティ設定の部分を変更
    // サーバーがNLAを要求しているので、NLAを有効にしたまま
    freerdp_settings_set_bool(settings, FreeRDP_NlaSecurity, TRUE);
    freerdp_settings_set_bool(settings, FreeRDP_TlsSecurity, TRUE);
    freerdp_settings_set_bool(settings, FreeRDP_RdpSecurity, TRUE);
    freerdp_settings_set_bool(settings, FreeRDP_IgnoreCertificate, TRUE);

    // EarlyCapabilityFlagsはUINT32型なので、正しい関数を使用
    freerdp_settings_set_uint32(settings, FreeRDP_EarlyCapabilityFlags, 1);

    // 型エラーが出ている設定項目の修正
    // OffscreenSupportLevelもUINT32タイプ
    freerdp_settings_set_uint32(settings, FreeRDP_OffscreenSupportLevel, 1);

    // 追加: NTLMサポートの設定
    freerdp_settings_set_bool(settings, FreeRDP_Authentication, TRUE);
    freerdp_settings_set_bool(settings, FreeRDP_DisableCredentialsDelegation, FALSE);

    // 追加: ネゴシエーションプロトコルを設定
    // PROTOCOL_HYBRID = 0 (NLA), PROTOCOL_SSL = 1 (TLS), PROTOCOL_RDP = 2 (RDP)
    freerdp_settings_set_uint32(settings, FreeRDP_NegotiationFlags, 0); // NLA (PROTOCOL_HYBRID)

    // UseRdpSecurityLayerはログファイルでは特に問題になっていないので削除
    // freerdp_settings_set_bool(settings, FreeRDP_UseRdpSecurityLayer, FALSE);

    // 元の設定を残す
    freerdp_settings_set_bool(settings, FreeRDP_FastPathInput, TRUE);
    freerdp_settings_set_bool(settings, FreeRDP_FastPathOutput, TRUE);
    
    
    
    // 以下のOpenSSL関連の設定を追加
    // OpenSSLが適切に初期化されるようにする
    freerdp_settings_set_bool(settings, FreeRDP_EarlyCapabilityFlags, TRUE);
    
    // 以下のコメントアウトまたは削除を検討（問題の原因かもしれない）
    // freerdp_settings_set_bool(settings, FreeRDP_UseRdpSecurityLayer, FALSE);
    
    // 型エラーが出ている設定項目の修正
    // OffscreenSupportLevelはUINT32タイプなので、BOOLではなくUINT32として設定
    freerdp_settings_set_uint32(settings, FreeRDP_OffscreenSupportLevel, 1);
    
    NSLog(@"セキュリティ設定: NLA=有効, TLS=有効, RDP=有効, 証明書検証=無効");
    
    // 圧縮設定
    freerdp_settings_set_bool(settings, FreeRDP_CompressionEnabled, _compressionEnabled);
    
    // その他の設定
    freerdp_settings_set_bool(settings, FreeRDP_BitmapCacheEnabled, TRUE);
    
    return YES;
}

- (BOOL)connectWithRDP {
    if (!_rdpInstance) {
        return NO;
    }
    
    // ★★★ 重要：WinPRがOpenSSLを初期化する前に環境変数を設定 ★★★
    // OpenSSL設定ファイルのパスを設定
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"openssl" ofType:@"cnf"];
    if (configPath) {
        setenv("OPENSSL_CONF", [configPath UTF8String], 1);
        NSLog(@"Set OPENSSL_CONF for WinPR: %@", configPath);
    }
    
    // OpenSSLモジュールディレクトリを設定
    NSString *opensslDir = [[NSBundle mainBundle] bundlePath];
    setenv("OPENSSL_MODULES", [[opensslDir stringByAppendingPathComponent:@"lib/ossl-modules"] UTF8String], 1);
    
    // 接続前にMD4を再確認（Objective-Cで）
    if ([OpenSSLHelper isMD4Available]) {
        NSLog(@"✓ MD4 available before FreeRDP connection");
    } else {
        NSLog(@"✗ MD4 NOT available before connection!");
        // 再度初期化を試みる
        [OpenSSLHelper forceMD4Registration];
    }
    
    // 接続前にエラーハンドリングを強化
    freerdp_settings_set_bool(_rdpInstance->context->settings, FreeRDP_GfxH264, FALSE);
    
    NSLog(@"RDP接続を開始します...");
    
    // 接続処理
    if (!freerdp_connect(_rdpInstance)) {
        UINT32 error = freerdp_get_last_error(_rdpInstance->context);
        NSString *errorName = [NSString stringWithUTF8String:freerdp_get_last_error_name(error)];
        NSLog(@"接続エラー: コード=%u (%@)", error, errorName);
        
        // エラーコードを分析
        switch (error) {
            case 0x2001D: // FREERDP_ERROR_CONNECT_CANCELLED
                NSLog(@"接続がキャンセルされました（NLA認証エラーの可能性）");
                break;
            case 0x20006: // FREERDP_ERROR_CONNECT_TRANSPORT_FAILED
                NSLog(@"トランスポート接続エラー（ポート番号または接続先に問題がある可能性）");
                // TLS接続の問題を解決するためNLAを無効化して再試行
                freerdp_settings_set_bool(_rdpInstance->context->settings, FreeRDP_NlaSecurity, FALSE);
                freerdp_settings_set_bool(_rdpInstance->context->settings, FreeRDP_TlsSecurity, TRUE);
                freerdp_settings_set_bool(_rdpInstance->context->settings, FreeRDP_RdpSecurity, TRUE);
                NSLog(@"NLAを無効にして再接続を試みます...");
                
                // 再接続を試みる
                if (!freerdp_connect(_rdpInstance)) {
                    error = freerdp_get_last_error(_rdpInstance->context);
                    NSLog(@"再接続も失敗: コード=%u (%s)",
                          error,
                          freerdp_get_last_error_name(error));
                    return NO;
                } else {
                    NSLog(@"再接続成功!");
                    return YES;
                }
                break;
            case 0x20009: // FREERDP_ERROR_AUTHENTICATION_FAILED
                NSLog(@"認証エラー（ユーザー名、パスワード、ドメインに問題がある可能性）");
                break;
            default:
                NSLog(@"その他のエラー: %@", errorName);
                break;
        }
        
        return NO;
    }
    
    NSLog(@"RDP接続が正常に確立されました！");
    return YES;
}

- (void)runRDPMainLoop {
    if (!_rdpInstance || !_rdpInstance->context) {
        return;
    }
    
    HANDLE handles[MAXIMUM_WAIT_OBJECTS];
    DWORD count;
    DWORD status;
    
    while (!freerdp_shall_disconnect_context(_rdpInstance->context)) {
        count = freerdp_get_event_handles(_rdpInstance->context, handles, MAXIMUM_WAIT_OBJECTS);
        
        if (count == 0) {
            NSLog(@"Failed to get event handles");
            break;
        }
        
        status = WaitForMultipleObjects(count, handles, FALSE, 100);
        
        if (status == WAIT_FAILED) {
            WLog_ERR("freerdp", "WaitForMultipleObjects failed with %lu", GetLastError());
            break;
        }
        
        if (!freerdp_check_event_handles(_rdpInstance->context)) {
            if (freerdp_get_last_error(_rdpInstance->context) == FREERDP_ERROR_SUCCESS) {
                WLog_ERR("freerdp", "Failed to check FreeRDP file descriptor");
            }
            break;
        }
    }
}

- (BOOL)testNetworkConnection {
    struct hostent *host_info;
    struct sockaddr_in server;
    
    host_info = gethostbyname([_host UTF8String]);
    if (host_info == NULL) {
        return NO;
    }
    
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        return NO;
    }
    
    server.sin_family = AF_INET;
    server.sin_port = htons(_port);
    memcpy(&server.sin_addr, host_info->h_addr, host_info->h_length);
    
    // タイムアウト設定
    struct timeval timeout;
    timeout.tv_sec = 2;
    timeout.tv_usec = 0;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
    
    // 接続試行
    int result = connect(sock, (struct sockaddr *)&server, sizeof(server));
    
    close(sock);
    return (result >= 0);
}

#pragma mark - Screen Update Handling

- (void)startUpdateTimer {
    [self stopUpdateTimer];
    
    // 画面更新チェックタイマー (30FPS)
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0/30.0
                                                        target: self
                                                      selector: @selector(checkForScreenUpdates)
                                                      userInfo: nil
                                                       repeats: YES];
    [[NSRunLoop currentRunLoop] addTimer: self.updateTimer
                                 forMode: NSRunLoopCommonModes];
}

- (void)stopUpdateTimer {
    if (_updateTimer) {
        [_updateTimer invalidate];
        _updateTimer = nil;
    }
}

- (void)checkForScreenUpdates {
    if (!_isConnected || !_rdpContext) {
        return;
    }
    
    if (self.hasUpdates) {
        self.hasUpdates = NO;
        [self captureAndNotifyScreenUpdate];
    }
}

- (void)captureAndNotifyScreenUpdate {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!self.rdpContext || !self.rdpContext->drawContext) {
            return;
        }
        
        EnterCriticalSection(&self.rdpContext->updateLock);
        
        // GDIコンテキストから画像を作成
        CGImageRef image = CGBitmapContextCreateImage(self.rdpContext->drawContext);
        LeaveCriticalSection(&self.rdpContext->updateLock);
        
        if (image) {
            [self notifyScreenUpdate: image];
            CGImageRelease(image);
        }
    });
}

#pragma mark - Input Handling

- (void)sendMouseEvent:(CGPoint)point isDown:(BOOL)isDown button:(int32_t)button {
    if (!_isConnected || !_rdpInstance || !_rdpInstance->context) {
        return;
    }
    
    // FreeRDP 3.x系では input は context->input でアクセス
    rdpInput* input = _rdpInstance->context->input;
    if (!input) {
        return;
    }
    
    UINT16 flags = 0;
    
    // ボタンの種類に応じてフラグを設定
    switch (button) {
        case 1: // 左ボタン
            flags = isDown ? PTR_FLAGS_DOWN : 0;
            flags |= PTR_FLAGS_BUTTON1;
            break;
        case 2: // 右ボタン
            flags = isDown ? PTR_FLAGS_DOWN : 0;
            flags |= PTR_FLAGS_BUTTON2;
            break;
        case 3: // 中央ボタン
            flags = isDown ? PTR_FLAGS_DOWN : 0;
            flags |= PTR_FLAGS_BUTTON3;
            break;
        default:
            return;
    }
    
    // マウスイベントを送信
    freerdp_input_send_mouse_event(input, flags, (UINT16)point.x, (UINT16)point.y);
}

- (void)sendKeyEvent:(int32_t)keyCode isDown:(BOOL)isDown {
    if (!_isConnected || !_rdpInstance || !_rdpInstance->context) {
        return;
    }
    
    rdpInput* input = _rdpInstance->context->input;
    if (!input) {
        return;
    }
    
    UINT16 flags = isDown ? KBD_FLAGS_DOWN : KBD_FLAGS_RELEASE;
    
    // キーイベントを送信
    freerdp_input_send_keyboard_event(input, flags, (UINT16)keyCode);
}

- (void)sendScrollEvent:(CGPoint)point delta:(CGFloat)delta {
    if (!_isConnected || !_rdpInstance || !_rdpInstance->context) {
        return;
    }
    
    rdpInput* input = _rdpInstance->context->input;
    if (!input) {
        return;
    }
    
    UINT16 flags = PTR_FLAGS_WHEEL;
    
    // スクロール方向の判定
    if (delta > 0) {
        flags |= PTR_FLAGS_WHEEL_NEGATIVE;
    }
    
    // スクロール量を調整（通常は120の倍数）
    int16_t scrollDelta = (int16_t)(delta * 120);
    
    // スクロールイベントを送信
    freerdp_input_send_mouse_event(input, flags, (UINT16)point.x, (UINT16)point.y);
}

#pragma mark - Notifications

// 画面更新通知
- (void)notifyScreenUpdate:(CGImageRef)image {
    if (_onScreenUpdateBlock) {
        self.onScreenUpdateBlock(image);
    }
}

// エラーメッセージ通知 
- (void)notifyError:(NSString *)errorMessage {
    NSLog(@"RDP Error: %@", errorMessage);
    if (_onErrorBlock) {
        self.onErrorBlock(errorMessage);
    }
}

#pragma mark - Configuration

- (void)setScreenSize:(CGSize)size {
    _screenSize = size;
    
    // 接続中の場合はリサイズを実行
    if (_rdpInstance && _rdpInstance->context && _rdpInstance->context->settings) {
        freerdp_settings_set_uint32(_rdpInstance->context->settings, FreeRDP_DesktopWidth, (UINT32)size.width);
        freerdp_settings_set_uint32(_rdpInstance->context->settings, FreeRDP_DesktopHeight, (UINT32)size.height);
    }
}

- (void)setColorDepth:(int32_t)colorDepth {
    _colorDepth = colorDepth;
    
    if (_rdpInstance && _rdpInstance->context && _rdpInstance->context->settings) {
        freerdp_settings_set_uint32(_rdpInstance->context->settings, FreeRDP_ColorDepth, colorDepth);
    }
}

- (void)setCompressionEnabled:(BOOL)enabled {
    _compressionEnabled = enabled;
    
    if (_rdpInstance && _rdpInstance->context && _rdpInstance->context->settings) {
        freerdp_settings_set_bool(_rdpInstance->context->settings, FreeRDP_CompressionEnabled, enabled);
    }
}

- (void)setSecurityLevel:(int32_t)level {
    _securityLevel = level;
}

- (void)enableDebugLogging:(BOOL)enabled {
    if (enabled) {
        WLog_SetLogLevel(WLog_GetRoot(), WLOG_DEBUG);
        WLog_SetLogLevel(WLog_Get("com.freerdp.core"), WLOG_DEBUG);
        WLog_SetLogLevel(WLog_Get("com.freerdp.gdi"), WLOG_DEBUG);
    } else {
        WLog_SetLogLevel(WLog_GetRoot(), WLOG_ERROR);
    }
    
    NSLog(@"FreeRDP debug logging %@", enabled ? @"enabled" : @"disabled");
}

@end

#pragma mark - FreeRDP Callback Implementations

// コンテキスト作成コールバック
static BOOL context_new(freerdp* instance, rdpContext* context) {
    MyRdpContext* myContext = (MyRdpContext*)context;
    
    if (!myContext) {
        return FALSE;
    }
    
    // クリティカルセクションの初期化
    InitializeCriticalSection(&myContext->updateLock);
    
    return TRUE;
}

// コンテキスト解放コールバック
static void context_free(freerdp* instance, rdpContext* context) {
    MyRdpContext* myContext = (MyRdpContext*)context;
    
    if (!myContext) {
        return;
    }
    
    // リソースの解放
    if (myContext->drawContext) {
        CGContextRelease(myContext->drawContext);
        myContext->drawContext = NULL;
    }
    
    DeleteCriticalSection(&myContext->updateLock);
}

// 接続前の初期化コールバック
static BOOL rdp_pre_connect(freerdp* instance) {
    if (!instance || !instance->context) {
        return FALSE;
    }
    
    // GDIの初期化
    if (!gdi_init(instance, PIXEL_FORMAT_BGRA32)) {
        NSLog(@"Failed to initialize GDI");
        return FALSE;
    }
    
    // 更新コールバックの設定
    instance->context->update->BeginPaint = gdi_begin_paint;
    instance->context->update->EndPaint = gdi_end_paint;
    
    return TRUE;
}

// 接続後の初期化コールバック
static BOOL rdp_post_connect(freerdp* instance) {
    if (!instance || !instance->context) {
        return FALSE;
    }
    
    MyRdpContext* myContext = (MyRdpContext*)instance->context;
    rdpGdi* gdi = instance->context->gdi;
    
    // 描画コンテキストの作成
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace) {
        return FALSE;
    }
    
    myContext->drawContext = CGBitmapContextCreate(
        gdi->primary_buffer,
        gdi->width,
        gdi->height,
        8,
        gdi->stride,
        colorSpace,
        kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst
    );
    
    CGColorSpaceRelease(colorSpace);
    
    if (!myContext->drawContext) {
        NSLog(@"Failed to create drawing context");
        return FALSE;
    }
    
    NSLog(@"RDP connection established successfully");
    return TRUE;
}

// 切断後のクリーンアップコールバック
static void rdp_post_disconnect(freerdp* instance) {
    if (!instance || !instance->context) {
        return;
    }
    
    NSLog(@"RDP disconnected");
}

// 認証コールバック
static BOOL rdp_authenticate(freerdp* instance, char** username, char** password, char** domain) {
    // 認証情報は既に設定済み
    return TRUE;
}

// 証明書検証コールバック（新API対応）
static DWORD rdp_verify_certificate_ex(freerdp* instance, const char* host, UINT16 port,
                                       const char* common_name, const char* subject,
                                       const char* issuer, const char* fingerprint,
                                       DWORD flags) {
    // 開発時は証明書を受け入れる（本番環境では適切な検証を実装）
    NSLog(@"Certificate verification: %s", common_name ? common_name : "unknown");
    return 1; // Accept certificate
}

// 変更された証明書検証コールバック
static DWORD rdp_verify_changed_certificate_ex(freerdp* instance, const char* host, UINT16 port,
                                               const char* common_name, const char* subject,
                                               const char* issuer, const char* fingerprint,
                                               const char* old_subject, const char* old_issuer,
                                               const char* old_fingerprint, DWORD flags) {
    // 開発時は証明書変更を受け入れる（本番環境では適切な検証を実装）
    NSLog(@"Changed certificate verification: %s (was: %s)",
          common_name ? common_name : "unknown",
          old_subject ? old_subject : "unknown");
    return 1; // Accept changed certificate
}

// 描画開始コールバック
static BOOL gdi_begin_paint(rdpContext* context) {
    MyRdpContext* myContext = (MyRdpContext*)context;
    
    if (myContext) {
        EnterCriticalSection(&myContext->updateLock);
    }
    
    return TRUE;
}

// 描画終了コールバック
static BOOL gdi_end_paint(rdpContext* context) {
    MyRdpContext* myContext = (MyRdpContext*)context;
    
    if (myContext) {
        myContext->hasUpdates = TRUE;
        
        // ブリッジオブジェクトに更新を通知
        if (myContext->bridge) {
            [myContext->bridge setHasUpdates:YES];
        }
        
        LeaveCriticalSection(&myContext->updateLock);
    }
    
    return TRUE;
}
