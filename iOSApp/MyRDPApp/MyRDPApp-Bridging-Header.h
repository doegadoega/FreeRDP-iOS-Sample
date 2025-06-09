//
//  MyRDPApp-Bridging-Header.h
//  MyRDPApp
//
//  Created on 2025/05/24.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

#ifndef MyRDPApp_Bridging_Header_h
#define MyRDPApp_Bridging_Header_h

// このファイルは、Swift から Objective-C コードにアクセスするためのブリッジングヘッダーです。
// Swift からアクセスしたい Objective-C のクラスや関数をここでインポートします。

// iOS フレームワーク
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

// FreeRDP ライブラリのインクルード順序は重要です
// 基本的なWinPRコンポーネントを先にインクルード
#import <winpr/stream.h>

// FreeRDP コアコンポーネント
#import <freerdp3/freerdp/freerdp.h>
#import <freerdp3/freerdp/client.h>

// GDIコンポーネントを先にインクルード（bitmap構造体の定義を優先）
#import <freerdp3/freerdp/gdi/gdi.h>

// その他のコンポーネント
#import <freerdp3/freerdp/channels/channels.h>

// カスタムブリッジ（最後にインクルード）
#import "RDP/FreeRDPBridge.h"

#endif /* MyRDPApp_Bridging_Header_h */

