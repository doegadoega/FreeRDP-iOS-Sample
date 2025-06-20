# FreeRDP iOS アプリ

## 🎯 概要

このプロジェクトは、FreeRDPライブラリを使用したiOS向けのRDPクライアントアプリケーションです。AWS EC2インスタンスへの接続や、リモートデスクトップの操作が可能です。

## 📋 システム要件

### 必須ソフトウェア
- **Xcode** 16.3以上
  - App Storeからインストール
  - インストール後、初回起動時に追加コンポーネントのインストールが必要

- **Command Line Tools**
  ```bash
  xcode-select --install
  ```

- **Homebrew**
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- **Git**
  - https://git-scm.com/download/mac から最新版をダウンロード
  - インストーラーを実行してインストール

- **Ruby環境とCocoaPods**
  ```bash
  # Rubyのインストール
  brew install ruby

  # Rubyのパスを設定（~/.zshrcまたは~/.bash_profileに追加）
  echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc

  # CocoaPodsのインストール
  gem install cocoapods
  pod setup
  ```

### 自動インストールされるソフトウェア
- **CMake** 3.13以上
  - ビルド時に自動的にGitHubからソースビルド
  - 手動インストール不要

### ハードウェア要件
- **macOS** を実行できるMac
  - Apple Silicon Mac（推奨）
  - Intel Mac（対応）

### 開発環境
- **iOS** 15.0以上
  - シミュレーター: iPhone 15 Pro（推奨）
  - 実機: iOS 15.0以上をサポートするデバイス

## 🚀 クイックスタート

### 1. リポジトリのクローン
```bash
git clone https://github.com/yourusername/FreeRDPiOSApp.git
cd FreeRDPiOSApp
```

### 2. 自動ビルド実行
```bash
./build.sh build
```

ビルドスクリプトが以下を自動で行います：
- ✅ CMake のGitHubからのソースビルド（必要な場合）
- ✅ CocoaPods のインストール
- ✅ FreeRDP ソースコードのダウンロード
- ✅ OpenSSL のビルド
- ✅ FreeRDP のビルド
- ✅ Xcode プロジェクトのセットアップ

### 3. アプリの実行
```bash
open MyRDPApp.xcworkspace
```

Xcodeで以下の手順を実行：
1. ターゲットデバイスを選択（iPhone 15 Pro シミュレーター推奨）
2. ビルドボタン（⌘+B）を押してビルド
3. 実行ボタン（⌘+R）を押してアプリを起動

## 🛠️ ビルドスクリプト

### メインビルドスクリプト
```bash
./build.sh build                    # 完全なビルドプロセスを実行
./build.sh build --target device    # 実機向けのみビルド
./build.sh build --target simulator # シミュレータ向けのみビルド
./build.sh deps                     # 依存関係のみをビルド
./build.sh clean                    # ビルド成果物をクリーン
./build.sh config                   # 設定情報の表示
./build.sh help                     # ヘルプの表示
```

### ビルドプロセスの詳細

#### 1. 依存ライブラリのビルド
- **OpenSSL** (バージョン 3.4.0)
  - iOSデバイス用とシミュレータ用の両方をビルド
  - ビルド済みライブラリは `iOSApp/Libraries/openssl` と `iOSApp/Libraries/openssl-simulator` に配置
  - 手動インストールは不要（自動ビルド）

- **FreeRDP** (バージョン 3.15.0)
  - OpenSSLライブラリに依存
  - iOSデバイス用とシミュレータ用の両方をビルド
  - ビルド済みライブラリは `iOSApp/Libraries/freerdp` と `iOSApp/Libraries/freerdp-simulator` に配置

#### 2. ビルド環境の要件
- **CMake** 3.13以上
  - 自動的にGitHubからソースビルド
  - 手動インストール不要

- **Xcode Command Line Tools**
  - ビルドに必要なコンパイラとツールチェーン
  - `xcode-select --install` でインストール

#### 3. ビルドプロセスの流れ
1. CMakeのビルド（必要な場合）
   - GitHubからCMakeリポジトリをクローン
   - 最新の安定版をビルド
   - `iOSApp/Libraries/cmake`にインストール

2. OpenSSLのビルド
   - GitHubからOpenSSLリポジトリをクローン
   - iOSデバイス用とシミュレータ用の両方をビルド
   - 必要なライブラリファイルを生成

3. FreeRDPのビルド
   - GitHubからFreeRDPリポジトリをクローン
   - OpenSSLライブラリを使用するように設定
   - iOSデバイス用とシミュレータ用の両方をビルド
   - 必要なライブラリファイルを生成

#### 4. トラブルシューティング
- ビルドエラーが発生した場合：
  ```bash
  # ビルドディレクトリをクリーンアップ
  ./build.sh clean
  
  # 再ビルド
  ./build.sh build
  ```

- 特定のターゲットのみをビルドする場合：
  ```bash
  # 実機向けのみビルド
  ./build.sh build --target device
  
  # シミュレータ向けのみビルド
  ./build.sh build --target simulator
  ```

## 📁 プロジェクト構成

```
FreeRDPiOSApp/
├── build.sh             # メインビルドスクリプト
├── scripts/             # ビルドスクリプト
│   ├── config.sh       # 共通設定
│   ├── build_openssl.sh # OpenSSLビルドスクリプト
│   └── build_freerdp.sh # FreeRDPビルドスクリプト
├── docs/               # プロジェクトドキュメント
├── iOSApp/            # アプリケーションのソースコード
│   ├── MyRDPApp/      # メインアプリケーション
│   └── Libraries/     # 依存ライブラリ
│       ├── openssl/   # 実機用OpenSSL
│       ├── openssl-simulator/ # シミュレータ用OpenSSL
│       ├── freerdp/   # 実機用FreeRDP
│       └── freerdp-simulator/ # シミュレータ用FreeRDP
└── project.yml        # XcodeGen設定ファイル
```

## 🧪 テスト

### テスト用認証情報
- `TESTDOMAIN\testuser1@test1.example.com:3389`
- `testuser2@test2.example.com:3389`
- `admin@192.168.1.100:3389`

### テスト実行
```bash
./test_app.sh
```

## ⚠️ 開発者向け注意事項

### ライブラリバージョン
- OpenSSL: 3.4.0
- FreeRDP: 3.16.0

### 変更制限
- ライブラリバージョンの変更は必ず承認が必要
- 重要設定ファイルの変更は事前承認が必要
- 作業開始前は必ずTODO.mdを確認

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細については[LICENSE](LICENSE)ファイルを参照してください。

## 🙏 謝辞

- [FreeRDP](https://github.com/FreeRDP/FreeRDP)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [CocoaPods](https://cocoapods.org)
