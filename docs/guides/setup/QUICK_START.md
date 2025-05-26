# FreeRDP iOS App - クイックスタートガイド

## 🚀 最速セットアップ（推奨）

### 前提条件の自動インストール
```bash
# 1. プロジェクトディレクトリに移動
cd FreeRDPiOSApp

# 2. 自動ビルド実行（必要な依存関係も自動インストール）
./build.sh build
```

ビルドスクリプトが以下を自動で行います：
- ✅ CMake のGitHubからのソースビルド（必要な場合）
- ✅ CocoaPods のインストール
- ✅ FreeRDP ソースコードのダウンロード
- ✅ OpenSSL のビルド
- ✅ FreeRDP のビルド
- ✅ Xcode プロジェクトのセットアップ

## 📱 Xcode での開発

### プロジェクトを開く
```bash
# CocoaPods使用の場合（推奨）
open MyRDPApp.xcworkspace

# または直接プロジェクトファイル
open MyRDPApp.xcodeproj
```

### 設定が必要な項目

#### 1. AWS設定
`AppDelegate.swift` の以下の部分を更新：
```swift
private func getAWSIdentityPoolId() -> String {
    return "YOUR_ACTUAL_IDENTITY_POOL_ID"  // ここを実際のIDに変更
}

private func getAWSRegion() -> String {
    return "ap-northeast-1"  // 必要に応じてリージョンを変更
}
```

#### 2. 開発チーム設定
Xcode で以下を設定：
1. プロジェクト設定を開く
2. "Signing & Capabilities" タブ
3. "Team" で自分の開発者アカウントを選択

## 🛠️ トラブルシューティング

### CMake エラーが出る場合
```bash
# ビルドディレクトリをクリーンアップして再試行
rm -rf build iOSApp/Libraries
./build.sh build
```

### CocoaPods エラーが出る場合
```bash
# CocoaPods を再インストール
sudo gem install cocoapods
pod setup
```

### ビルドエラーが出る場合
```bash
# クリーンビルド
./build.sh clean
./build.sh build
```

## 🎯 開発モード

### 依存関係のみビルド
```bash
./build.sh deps
```

### プロジェクトのみビルド
```bash
./build.sh project
```

### 完全クリーン
```bash
./build.sh clean
```

## 📋 チェックリスト

開発開始前に以下を確認：

- [ ] Xcode がインストール済み
- [ ] Apple Developer アカウントでサインイン済み
- [ ] AWS Cognito アイデンティティプール作成済み
- [ ] EC2 インスタンスのセキュリティグループでRDPポート(3389)開放済み

## 🔧 手動セットアップ（上級者向け）

自動ビルドを使わない場合：

### 1. 依存関係のインストール
```bash
# CocoaPods
sudo gem install cocoapods
```

### 2. FreeRDP のビルド
```bash
# FreeRDP ソースコードのクローン
git clone --depth 1 --branch 2.11.2 https://github.com/FreeRDP/FreeRDP.git iOSApp/Libraries/FreeRDP

# OpenSSL のビルド
cd iOSApp/Libraries/FreeRDP
chmod +x scripts/build_openssl.sh
./scripts/build_openssl.sh

# FreeRDP のビルド
mkdir -p build/ios
cd build/ios
cmake ../.. -DCMAKE_TOOLCHAIN_FILE=../../cmake/ios.toolchain.cmake -DIOS_PLATFORM=OS -DCMAKE_BUILD_TYPE=Release
make -j$(sysctl -n hw.ncpu)
```

### 3. ライブラリのコピー
```bash
# ビルドされたライブラリをプロジェクトにコピー
mkdir -p libs
find iOSApp/Libraries/FreeRDP/build/ios -name "*.a" -exec cp {} libs/ \;
find iOSApp/Libraries/FreeRDP/Libraries/openssl -name "*.a" -exec cp {} libs/ \;
```

## 🎉 完了！

セットアップが完了したら：
1. Xcode で `MyRDPApp.xcworkspace` を開く
2. iPhone 15 Pro シミュレーターでビルド・実行
3. AWS EC2 インスタンスへの接続をテスト

## 📞 サポート

問題が発生した場合：
1. `./build.sh help` でオプションを確認
2. `README.md` で詳細なドキュメントを確認
3. `PROJECT_SUMMARY.md` で技術仕様を確認
