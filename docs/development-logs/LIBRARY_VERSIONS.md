# 外部ライブラリバージョン情報

このドキュメントでは、FreeRDPiOSSampleプロジェクトで使用されている外部ライブラリのバージョン情報を記録しています。

## 現在のバージョン (2024年5月25日更新)

| ライブラリ名 | バージョン | ソース | ビルド方法 |
|------------|----------|------|----------|
| OpenSSL    | 3.4.0    | [GitHub](https://github.com/openssl/openssl) | `scripts/build_openssl.sh` |
| FreeRDP    | 3.15.0   | [GitHub](https://github.com/FreeRDP/FreeRDP) | `scripts/build_freerdp.sh` |

## バージョン履歴

### OpenSSL

| 日付 | バージョン | 変更内容 |
|------|----------|----------|
| 2024-05-24 | 3.4.0 | 初期実装 |

### FreeRDP

| 日付 | バージョン | 変更内容 |
|------|----------|----------|
| 2024-05-24 | 3.15.0 | 初期実装 |

## バージョン更新時の注意事項

ライブラリのバージョンを更新する際は、以下の手順に従ってください：

1. 本ドキュメントのバージョン情報を更新する
2. 対応するビルドスクリプト内のバージョン番号を更新する:
   - OpenSSL: `scripts/build_openssl.sh` の `OPENSSL_VERSION_NUMBER` 変数
   - FreeRDP: `scripts/build_freerdp.sh` の `FREERDP_VERSION` 変数
3. 既存のビルドディレクトリをクリーンアップする: `rm -rf build/openssl build/freerdp`
4. ライブラリを再ビルドする: `./scripts/build.sh`
5. iOS アプリのビルドとテストを行い、互換性を確認する
6. 問題がなければ変更をコミットする

## 互換性情報

### OpenSSL

- **最小サポートバージョン**: 3.0.0
- **推奨バージョン**: 3.4.0
- **iOSサポート**: iOS 15.0+

### FreeRDP

- **最小サポートバージョン**: 3.0.0
- **推奨バージョン**: 3.15.0
- **iOSサポート**: iOS 15.0+

## 依存関係

- FreeRDPはOpenSSLに依存しています
- バージョンの整合性を維持するため、両方のライブラリを同時に更新することを推奨します 