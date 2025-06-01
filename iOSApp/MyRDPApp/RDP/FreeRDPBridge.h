//
//  FreeRDPBridge.h
//  MyRDPApp
//
//  Created on 2025/05/23.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/// FreeRDPのネイティブライブラリとiOSアプリの間のブリッジングクラス
@interface FreeRDPBridge : NSObject

/**
 * シングルトンインスタンスを取得
 */
+ (instancetype)sharedInstance;

#pragma mark - Connection Management

/**
 * RDPサーバーに接続
 * @param host ホスト名またはIPアドレス
 * @param port ポート番号（通常は3389）
 * @param username ユーザー名
 * @param password パスワード
 * @param domain ドメイン名（オプション、nilまたは空文字列可）
 * @return 接続プロセスが開始されたかどうか
 */
- (BOOL)connectToHost:(NSString *)host
                 port:(int32_t)port
             username:(NSString *)username
             password:(NSString *)password
               domain:(nullable NSString *)domain;

/**
 * 接続を切断
 */
- (void)disconnect;

#pragma mark - Callback Setters

/**
 * 接続状態が変更されたときのコールバックを設定
 * @param block 接続状態が変更されたときに呼ばれるブロック。引数はYESなら接続、NOなら切断。
 */
- (void)setOnConnectionStateChanged:(nullable void (^)(BOOL connected))block;

/**
 * エラーが発生したときのコールバックを設定
 * @param block エラーが発生したときに呼ばれるブロック。引数はエラーメッセージ。
 */
- (void)setOnError:(nullable void (^)(NSString *errorMessage))block;

/**
 * 画面が更新されたときのコールバックを設定
 * @param block 画面が更新されたときに呼ばれるブロック。引数は更新された画像。
 */
- (void)setOnScreenUpdate:(nullable void (^)(CGImageRef image))block;

#pragma mark - Input Handling

/**
 * マウスイベントを送信
 * @param point マウス座標
 * @param isDown ボタンが押されているかどうか
 * @param button ボタン番号（1: 左、2: 右、3: 中央）
 */
- (void)sendMouseEvent:(CGPoint)point isDown:(BOOL)isDown button:(int32_t)button;

/**
 * キーイベントを送信
 * @param keyCode キーコード
 * @param isDown キーが押されているかどうか
 */
- (void)sendKeyEvent:(int32_t)keyCode isDown:(BOOL)isDown;

/**
 * スクロールイベントを送信
 * @param point マウス座標
 * @param delta スクロール量
 */
- (void)sendScrollEvent:(CGPoint)point delta:(CGFloat)delta;

#pragma mark - Configuration

/**
 * 画面サイズを設定
 * @param size 画面サイズ
 */
- (void)setScreenSize:(CGSize)size;

/**
 * 色深度を設定
 * @param colorDepth 色深度（通常は16または32）
 */
- (void)setColorDepth:(int32_t)colorDepth;

/**
 * 圧縮を有効/無効にする
 * @param enabled 圧縮を有効にするかどうか
 */
- (void)setCompressionEnabled:(BOOL)enabled;

/**
 * セキュリティレベルを設定
 * @param level セキュリティレベル
 */
- (void)setSecurityLevel:(int32_t)level;

/**
 * デバッグログを有効/無効にする
 * @param enabled デバッグログを有効にするかどうか
 */
- (void)enableDebugLogging:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
