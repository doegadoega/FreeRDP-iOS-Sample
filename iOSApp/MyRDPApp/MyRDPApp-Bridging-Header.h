//
//  MyRDPApp-Bridging-Header.h
//  MyRDPApp
//
//  Created on 2025/05/24.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

#ifndef MyRDPApp_Bridging_Header_h
#define MyRDPApp_Bridging_Header_h

// ==========================================
// iOS フレームワーク
// ==========================================
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

// ==========================================
// FreeRDP ライブラリ（順序重要）
// ==========================================
// 基本的なWinPRコンポーネント
#import <winpr/stream.h>

// FreeRDP コアコンポーネント
#import <freerdp3/freerdp/freerdp.h>
#import <freerdp3/freerdp/client.h>

// GDIコンポーネント（bitmap構造体の定義を優先）
#import <freerdp3/freerdp/gdi/gdi.h>

// その他のコンポーネント
#import <freerdp3/freerdp/channels/channels.h>

// ==========================================
// OpenSSL ライブラリ
// ==========================================
#import <openssl/crypto.h>
#import <openssl/evp.h>
#import <openssl/err.h>
#import <openssl/provider.h>
#import <openssl/md4.h>
#import <openssl/engine.h>

// ==========================================
// winpr ライブラリ
// ==========================================
#import <winpr/ssl.h>
#import <winpr/wlog.h>

// ==========================================
// カスタムクラス
// ==========================================
#import "RDP/FreeRDPBridge.h"
#import "OpenSSLHelper.h"

// ==========================================
// OpenSSL 定数
// ==========================================
#ifndef EVP_MAX_MD_SIZE
#define EVP_MAX_MD_SIZE 64
#endif

// ==========================================
// OpenSSL 関数宣言は不要
// ==========================================
// 注意: 以下の関数は既にOpenSSLヘッダーで宣言されているため、
// 再宣言は不要です：
// - EVP_get_digestbyname
// - EVP_Digest
// - OPENSSL_add_all_algorithms_noconf

#endif /* MyRDPApp_Bridging_Header_h */
