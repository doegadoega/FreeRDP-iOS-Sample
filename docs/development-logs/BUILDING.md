# FreeRDPiOSSample ビルド手順

このドキュメントではFreeRDPiOSSampleプロジェクトのビルド方法について説明します。

## ビルド手順

## 前提条件

### 必須ソフトウェア
- Xcode 16.3以上
- Command Line Tools
- Homebrew
- Git
- Ruby環境とCocoaPods

### 自動インストールされるソフトウェア
- CMake 3.13以上（自動ビルド）
- CocoaPods（自動インストール）
- XcodeGen（自動インストール）

## XcodeGenについて

### 概要
- XcodeGenは、YAMLファイルからXcodeプロジェクトを生成するツールです
- プロジェクト設定をコードで管理できるため、チーム開発での設定の共有が容易になります
- 本プロジェクトでは`project.yml`を使用してプロジェクト設定を管理しています

### 自動インストール
- ビルドスクリプト実行時に自動的にインストールされます
- インストール先: `iOSApp/Libraries/xcodegen`

### 手動インストール（必要な場合）
```bash
# Homebrewを使用
brew install xcodegen

# または、ソースからビルド
git clone https://github.com/yonaskolb/XcodeGen.git
cd XcodeGen
make build
```

### プロジェクト生成
```bash
# プロジェクトの生成
xcodegen generate

# 特定の設定ファイルを指定
xcodegen generate --spec project.yml
```

### 設定ファイル（project.yml）
- プロジェクトの基本設定
- ターゲット設定
- ビルド設定
- 依存関係の管理
- スキーム設定

### 注意事項
- `project.yml`の変更は事前承認が必要です
- 重要な設定変更は必ずチームで確認してください
- ビルド設定の変更は慎重に行ってください

## ビルドプロセス

### 1. 依存ライブラリのビルド

#### OpenSSL (3.4.0)
- デバイス用とシミュレータ用の両方をビルド
- ビルド済みライブラリの配置場所：
  - デバイス用: `iOSApp/Libraries/openssl`
  - シミュレータ用: `iOSApp/Libraries/openssl-simulator`

#### FreeRDP (3.15.0)
- OpenSSLライブラリに依存
- デバイス用とシミュレータ用の両方をビルド
- ビルド済みライブラリの配置場所：
  - デバイス用: `iOSApp/Libraries/freerdp`
  - シミュレータ用: `iOSApp/Libraries/freerdp-simulator`

### 2. ビルドスクリプトの使用方法

#### メインビルドスクリプト
```bash
./scripts/build.sh build    # 完全なビルドプロセスを実行
./scripts/build.sh deps     # 依存関係のみをビルド
./scripts/build.sh clean    # ビルド成果物をクリーン
```

#### 個別のビルドスクリプト
```bash
./scripts/build_freerdp.sh  # FreeRDPライブラリのみをビルド
./scripts/build_openssl.sh  # OpenSSLライブラリのみをビルド
```

### 3. ビルドプロセスの流れ

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

## トラブルシューティング

### ビルドエラー時の対処法

1. ビルドディレクトリのクリーンアップ
```bash
rm -rf build iOSApp/Libraries
```

2. 再ビルド
```bash
./scripts/build.sh build
```

### 個別ライブラリの再ビルド

1. OpenSSLのみ再ビルド
```bash
./scripts/build_openssl.sh
```

2. FreeRDPのみ再ビルド
```bash
./scripts/build_freerdp.sh
```

## 注意事項

- ライブラリバージョンの変更は必ず承認が必要
- ビルド設定の変更は事前承認が必要
- 既存の動作している機能の変更は事前承認が必要

## 依存ライブラリ

このプロジェクトは以下の外部ライブラリに依存しています：

1. **OpenSSL** (バージョン 3.4.0)
   - TLS接続とセキュリティ機能に使用
   - ソースからビルドされます（手動インストール不要）

2. **FreeRDP** (バージョン 3.15.0)
   - RDPクライアント機能の実装
   - ソースからビルドされます（手動インストール不要）

## ビルド手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/your-username/FreeRDPiOSSample.git
cd FreeRDPiOSSample
```

### 2. 依存ライブラリのビルド

以下のコマンドを実行して、OpenSSLとFreeRDPライブラリをビルドします：

```bash
./scripts/build.sh
```

このスクリプトは以下の処理を行います：

1. CMakeのビルド（必要な場合）
   - GitHubからCMakeリポジトリをクローン
   - 最新の安定版をビルド
   - `iOSApp/Libraries/cmake`にインストール

2. OpenSSLのビルド (`scripts/build_openssl.sh`)
   - GitHubからOpenSSLリポジトリをクローン
   - iOS デバイス用とシミュレータ用の両方をビルド
   - ビルド済みライブラリは `iOSApp/Libraries/openssl` と `iOSApp/Libraries/openssl-simulator` に配置

3. FreeRDPのビルド (`scripts/build_freerdp.sh`)
   - GitHubからFreeRDPリポジトリをクローン
   - iOS デバイス用とシミュレータ用の両方をビルド
   - OpenSSLライブラリを使用するように設定
   - ビルド済みライブラリは `iOSApp/Libraries/freerdp` と `iOSApp/Libraries/freerdp-simulator` に配置

### 3. Xcodeプロジェクトのビルド

依存ライブラリのビルドが完了したら、Xcodeでプロジェクトを開いてビルドできます：

```bash
open FreeRDPiOSSample.xcodeproj
```

Xcodeで以下の手順を実行します：

1. ターゲットデバイスを選択（iPhone 15 Pro シミュレーター推奨）
2. ビルドボタン（⌘+B）を押してビルド
3. 実行ボタン（⌘+R）を押してアプリを起動

## 注意事項

- このビルドプロセスは、arm64アーキテクチャ（Apple Silicon MacおよびiOS）に最適化されています
- ビルド中に問題が発生した場合は、ログを確認して具体的なエラー内容を把握してください
- OpenSSLとFreeRDPのビルドには数分かかることがあります

## カスタマイズ

特定のライブラリだけを再ビルドする場合は、個別のスクリプトを実行できます：

```bash
# OpenSSLのみ再ビルド
./scripts/build_openssl.sh

# FreeRDPのみ再ビルド
./scripts/build_freerdp.sh
``` 