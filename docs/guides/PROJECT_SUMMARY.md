# FreeRDP iOS App - プロジェクト概要

## 概要

このプロジェクトは、FreeRDPライブラリを使用してAWS EC2上のWindowsインスタンスに接続するiOSアプリケーションの完全な実装例です。日本語のガイドドキュメントに基づいて作成されており、実際のプロダクション環境で使用可能な構造となっています。

## プロジェクト構成

```
FreeRDPiOSApp/
├── README.md                    # プロジェクト説明とセットアップガイド
├── Podfile                      # CocoaPods依存関係定義
├── build.sh                     # 自動ビルドスクリプト
├── PROJECT_SUMMARY.md           # このファイル
├── FreeRDPBridge.h             # Objective-C++ブリッジヘッダー
├── FreeRDPBridge.m             # FreeRDPライブラリとのブリッジ実装
├── RDPConnectionManager.swift   # RDP接続管理クラス
├── RDPScreenView.swift         # リモート画面表示とタッチ処理
├── AWSIntegration.swift        # AWS EC2インスタンス管理
├── CredentialStore.swift       # 認証情報の安全な保存
├── ViewController.swift        # メインビューコントローラー
└── AppDelegate.swift           # アプリケーションライフサイクル管理
```

## 主要機能

### 1. FreeRDP統合
- **FreeRDPBridge.h/m**: C/C++のFreeRDPライブラリをSwiftから使用するためのブリッジ
- **RDPConnectionManager.swift**: RDP接続の管理、画面更新、入力処理
- OpenSSLを使用したセキュアな接続

### 2. AWS EC2統合
- **AWSIntegration.swift**: EC2インスタンスの一覧取得、起動、停止、再起動
- AWS Cognitoを使用した認証
- モックデータによるテスト機能

### 3. ユーザーインターフェース
- **RDPScreenView.swift**: リモートデスクトップ画面の表示
- マルチタッチジェスチャー対応（タップ、長押し、パン、ピンチ、スワイプ）
- ズーム・スクロール機能
- 接続状態の視覚的フィードバック

### 4. セキュリティ
- **CredentialStore.swift**: キーチェーンを使用した認証情報の安全な保存
- 暗号化されたパスワード保存
- バックアップ・復元機能

### 5. アプリケーション管理
- **AppDelegate.swift**: アプリライフサイクル管理
- **ViewController.swift**: メイン画面とユーザー操作の処理
- バックグラウンド・フォアグラウンド処理

## 技術仕様

### 開発環境要件
- macOS (最新版推奨)
- Xcode 12以上
- CMake 3.13以上
- CocoaPods
- Git

### 依存ライブラリ
- FreeRDP 2.11.2
- OpenSSL 1.1.1w
- AWS SDK for iOS (AWSCore, AWSEC2)

### 対応iOS版本
- iOS 13.0以上
- iPhone/iPad対応

## ビルド手順

### 自動ビルド（推奨）
```bash
cd FreeRDPiOSApp
./build.sh build
```

### 手動ビルド
1. 依存関係のビルド:
```bash
./build.sh deps
```

2. Xcodeプロジェクトのセットアップ:
```bash
./build.sh project
```

### ビルドスクリプトオプション
- `./build.sh build` - 完全ビルド
- `./build.sh clean` - クリーンアップ
- `./build.sh deps` - 依存関係のみビルド
- `./build.sh project` - iOSプロジェクトのみビルド
- `./build.sh help` - ヘルプ表示

## 設定

### AWS設定
1. AWS Cognitoアイデンティティプールの作成
2. EC2インスタンスへのアクセス権限設定
3. `AppDelegate.swift`内の設定値更新:
```swift
let identityPoolId = "YOUR_IDENTITY_POOL_ID"
let region = "ap-northeast-1"
```

### FreeRDP設定
- 接続品質の調整
- セキュリティ設定
- デバッグログの有効化

## 使用方法

### 基本的な接続フロー
1. アプリ起動
2. AWS EC2インスタンス一覧の取得
3. 接続先インスタンスの選択
4. 必要に応じてインスタンスの起動
5. 認証情報の入力
6. RDP接続の確立
7. リモートデスクトップの操作

### ジェスチャー操作
- **タップ**: 左クリック
- **長押し**: 右クリック
- **パン**: ドラッグ操作
- **ピンチ**: ズーム
- **2本指スワイプ**: キーボードショートカット

## セキュリティ考慮事項

### 認証情報の保護
- キーチェーンによる暗号化保存
- アプリ削除時の自動クリーンアップ
- バイオメトリクス認証対応（実装可能）

### 通信セキュリティ
- TLS/SSL暗号化
- 証明書検証
- ネットワークレベル認証（NLA）

### AWS セキュリティ
- IAMロールによる最小権限の原則
- VPCセキュリティグループの適切な設定
- CloudTrailによる操作ログ

## トラブルシューティング

### よくある問題

1. **ビルドエラー**
   - CMakeバージョンの確認
   - Xcodeコマンドラインツールのインストール
   - 依存関係の再ビルド

2. **接続エラー**
   - AWSセキュリティグループの設定確認
   - EC2インスタンスの状態確認
   - 認証情報の確認

3. **パフォーマンス問題**
   - ネットワーク品質の確認
   - 画質設定の調整
   - デバイスリソースの確認

### デバッグ方法
```swift
#if DEBUG
// デバッグログの有効化
credentialStore.debugPrintAllCredentials()
#endif
```

## 拡張可能性

### 追加可能な機能
- ファイル転送機能
- 音声転送
- プリンター共有
- クリップボード共有
- マルチモニター対応

### カスタマイズポイント
- UI/UXの改善
- 接続プロファイルの管理
- 自動接続機能
- 接続履歴の管理

## ライセンス

このプロジェクトは以下のライセンスに従います：
- FreeRDP: Apache 2.0 License
- OpenSSL: OpenSSL License
- AWS SDK: Apache 2.0 License

## 貢献

プロジェクトへの貢献を歓迎します：
1. Issueの報告
2. 機能改善の提案
3. プルリクエストの送信
4. ドキュメントの改善

## サポート

技術的な質問やサポートが必要な場合：
1. プロジェクトのIssueページを確認
2. FreeRDPコミュニティフォーラム
3. AWS開発者フォーラム

## 更新履歴

### v1.0.0 (2025/05/23)
- 初期リリース
- FreeRDP統合
- AWS EC2統合
- 基本的なRDP接続機能
- セキュアな認証情報保存
- マルチタッチジェスチャー対応

## 今後の計画

### 短期目標
- UIの改善
- エラーハンドリングの強化
- パフォーマンス最適化

### 長期目標
- ファイル転送機能の追加
- 音声転送の実装
- マルチプラットフォーム対応

---

このプロジェクトは、FreeRDPを使用したiOSアプリ開発の包括的な例として作成されました。実際のプロダクション環境での使用を想定した設計となっており、セキュリティとパフォーマンスの両面で最適化されています。
