//
//  FreeRDPBridge.h
//  MyRDPApp
//
//  Created on 2025/05/23.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>

NS_ASSUME_NONNULL_BEGIN

/// FreeRDPのネイティブライブラリとiOSアプリの間のブリッジングクラス
@interface FreeRDPBridge : NSObject

/// 初期化（シングルトン）
+ (instancetype)sharedInstance;

/// RDPサーバーへの接続
/// @param host ホスト名またはIPアドレス
/// @param port ポート番号（通常は3389）
/// @param username ユーザー名
/// @param password パスワード
/// @param domain ドメイン名（オプション）
/// @return 接続プロセスが開始されたかどうか
- (BOOL)connectToHost:(NSString *)host
                 port:(int32_t)port
             username:(NSString *)username
             password:(NSString *)password
               domain:(NSString *)domain;

/// 接続を切断
- (void)disconnect;

/// マウスイベントの送信
/// @param point 画面上の座標
/// @param isDown ボタンが押されているかどうか
/// @param button ボタン（1=左、2=右、3=中）
- (void)sendMouseEvent:(CGPoint)point isDown:(BOOL)isDown button:(int32_t)button;

/// キーイベントの送信
/// @param keyCode キーコード
/// @param isDown キーが押されているかどうか
- (void)sendKeyEvent:(int32_t)keyCode isDown:(BOOL)isDown;

/// スクロールイベントの送信
/// @param point 画面上の座標
/// @param delta スクロール量
- (void)sendScrollEvent:(CGPoint)point delta:(CGFloat)delta;

/// 画面サイズの設定
/// @param size 画面サイズ
- (void)setScreenSize:(CGSize)size;

/// 色深度の設定
/// @param colorDepth 色深度（通常は16または32）
- (void)setColorDepth:(int32_t)colorDepth;

/// 圧縮の有効/無効設定
/// @param enabled 圧縮を有効にするかどうか
- (void)setCompressionEnabled:(BOOL)enabled;

/// セキュリティレベルの設定
/// @param level セキュリティレベル（0-3）
- (void)setSecurityLevel:(int32_t)level;

/// デバッグログの有効/無効設定
/// @param enabled デバッグログを有効にするかどうか
- (void)enableDebugLogging:(BOOL)enabled;

/// 高度なRDP接続テスト
- (void)testAdvancedRDPConnection;

#pragma mark - コールバック設定

/// 接続状態変更通知ブロック
/// @param block 状態変更時に呼び出されるブロック
- (void)setOnConnectionStateChanged:(void (^)(BOOL isConnected))block;

/// エラー通知ブロック
/// @param block エラー発生時に呼び出されるブロック
- (void)setOnError:(void (^)(NSString *errorMessage))block;

/// 画面更新通知ブロック
/// @param block 画面更新時に呼び出されるブロック
- (void)setOnScreenUpdate:(void (^)(CGImageRef image))block;

@end

NS_ASSUME_NONNULL_END
