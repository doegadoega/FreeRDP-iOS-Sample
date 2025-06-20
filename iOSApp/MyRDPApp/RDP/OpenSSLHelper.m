//
//  OpenSSLHelper.m
//  MyRDPApp
//
//  Created by Hiroshi Egami on 2025/06/20.
//

#import "OpenSSLHelper.h"
// OpenSSLヘッダーの順序が重要
#import <openssl/crypto.h>
#import <openssl/evp.h>
#import <openssl/err.h>
#import <openssl/objects.h>
#import <openssl/provider.h>
#import <openssl/md4.h>

@implementation OpenSSLHelper

+ (BOOL)initializeOpenSSL {
    NSLog(@"=== OpenSSL Initialization ===");
    
    // 1. 基本初期化（これで十分）
    OPENSSL_init_crypto(OPENSSL_INIT_ADD_ALL_CIPHERS | OPENSSL_INIT_ADD_ALL_DIGESTS, NULL);
    
    // 2. OpenSSL_add_all_algorithms_noconf()は不要（上記で代替）
    // OPENSSL_add_all_algorithms_noconf(); // この行を削除
    
    // 3. MD4を確実に追加
    const EVP_MD *md4 = EVP_md4();
    if (md4) {
        EVP_add_digest(md4);
        NSLog(@"✓ MD4 added to digest table");
        
        int nid = EVP_MD_type(md4);
        NSLog(@"MD4 NID: %d", nid);
        
        const char *name = OBJ_nid2sn(nid);
        NSLog(@"MD4 short name: %s", name);
    }
    
    return YES;
}

+ (BOOL)testMD4Direct {
    NSLog(@"=== Direct MD4 Test (Using MD4_* functions) ===");
    
    // MD4の直接API使用
    MD4_CTX ctx;
    unsigned char md[MD4_DIGEST_LENGTH];
    const char *test_data = "test";
    
    MD4_Init(&ctx);
    MD4_Update(&ctx, test_data, strlen(test_data));
    MD4_Final(md, &ctx);
    
    NSMutableString *hashString = [NSMutableString string];
    for (int i = 0; i < MD4_DIGEST_LENGTH; i++) {
        [hashString appendFormat:@"%02x", md[i]];
    }
    NSLog(@"✓ MD4 hash (direct): %@", hashString);
    
    return YES;
}

+ (BOOL)testMD4OneShot {
    NSLog(@"=== MD4 One-shot Test ===");
    
    const char *test_data = "test";
    unsigned char md[MD4_DIGEST_LENGTH];
    
    // MD4の簡易API
    MD4((const unsigned char *)test_data, strlen(test_data), md);
    
    NSMutableString *hashString = [NSMutableString string];
    for (int i = 0; i < MD4_DIGEST_LENGTH; i++) {
        [hashString appendFormat:@"%02x", md[i]];
    }
    NSLog(@"✓ MD4 hash (one-shot): %@", hashString);
    
    return YES;
}

+ (void)forceMD4Registration {
    NSLog(@"=== Force MD4 Registration (Fixed) ===");
    
    // まず直接APIで動作確認
    [self testMD4Direct];
    [self testMD4OneShot];
    
    // EVP層での登録
    const EVP_MD *md4 = EVP_md4();
    if (md4) {
        EVP_add_digest(md4);
        
        // 再度取得して確認
        const EVP_MD *check = EVP_get_digestbyname("MD4");
        if (check) {
            NSLog(@"✓ MD4 successfully registered in EVP");
            
            // プロバイダーチェック
            OSSL_PROVIDER *prov = EVP_MD_get0_provider(check);
            if (prov) {
                const char *prov_name = OSSL_PROVIDER_get0_name(prov);
                NSLog(@"MD4 provider: %s", prov_name ? prov_name : "unknown");
            } else {
                NSLog(@"MD4 provider: built-in");
            }
        }
    }
}

+ (BOOL)isMD4Available {
    // 直接APIのテスト
    [self testMD4Direct];
    
    // EVP APIのテスト
    const EVP_MD *md4 = EVP_get_digestbyname("MD4");
    return (md4 != NULL);
}

@end
