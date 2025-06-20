//
//  OpenSSLHelper.h
//  MyRDPApp
//
//  Created by Hiroshi Egami on 2025/06/20.
//

#import <Foundation/Foundation.h>

@interface OpenSSLHelper : NSObject
+ (BOOL)initializeOpenSSL;
+ (BOOL)isMD4Available;
+ (void)forceMD4Registration;
@end
