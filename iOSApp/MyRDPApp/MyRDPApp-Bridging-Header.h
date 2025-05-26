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

// FreeRDP Bridge
#import "RDP/FreeRDPBridge.h"

// iOS フレームワーク
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

// FreeRDPライブラリのヘッダー（iOSApp/Librariesディレクトリに配置されています）
// #import <freerdp3/freerdp/freerdp.h>
// #import <freerdp3/freerdp/client/client.h>
// #import <freerdp3/freerdp/channels/channels.h>
// #import <freerdp3/freerdp/gdi/gdi.h>

#endif /* MyRDPApp_Bridging_Header_h */
