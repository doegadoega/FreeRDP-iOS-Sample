# OpenSSL 3.x + FreeRDP + iOS: MD4/RC4問題の作業ログ

## 問題の発見
- RDP接続時に以下のエラーが発生し、NTLM認証が失敗
  [ERROR][com.winpr.crypto.hash] - [winpr_Digest_Init_Internal]: Failed to initialize digest md4
  [ERROR][com.winpr.sspi.NTLM] - [ntlm_init_rc4_seal_states]: Failed to allocate context->SendRc4Seal
- NTLM認証でMD4が必要だが、使用できないためRDP接続ができない

## 原因の特定
- OpenSSL 3.xの仕様変更により、MD4/RC4はレガシープロバイダー扱いとなりデフォルトで利用不可
- iOSは静的リンクのみ許可、プロバイダーの動的ロードが困難

## 試行錯誤
- ❌ enable-md4/enable-rc4でビルド → 実行時に使えない
- ❌ openssl.cnfでlegacy有効化 → FreeRDP/WinPR側で無効
- ❌ OSSL_PROVIDER_load(NULL, "legacy") → WinPRのOpenSSLコンテキストで無効
- ❌ OSSL_PROVIDER_add_builtin(nil, ...) → 内部関数にアクセスできない

## 根本原因
- WinPRが独自にOpenSSLを初期化する際、レガシープロバイダーを読み込まない
- iOSの静的リンク環境ではプロバイダー機構が機能しない

## 最終的な解決策
- FreeRDPの内部MD4/RC4実装を有効化（CMakeオプション: -DWITH_INTERNAL_MD4=ON -DWITH_INTERNAL_RC4=ON）
- OpenSSLに依存しない実装でNTLM認証が動作

## 教訓・注意点
- 依存関係（FreeRDP→WinPR→OpenSSL）の理解が重要
- WITH_INTERNAL_MD4等のビルドオプションを活用
- iOSシミュレータではRDP接続が正常動作しない場合がある。必ず実機で検証
- MD4/RC4は現代のセキュリティ基準では非推奨。将来的には安全な認証方式への移行を推奨
