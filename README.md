# FreeRDP iOS アプリ - 完全ビルドガイド

## 🎯 プロジェクト概要

このプロジェクトは、オープンソースのリモートデスクトッププロトコルライブラリ **FreeRDP** をiOS向けにクロスビルドし、実際に動作するiOSアプリ（`MyRDPApp`）からRDP接続を実現する実用的なプロジェクトです。

### 📱 何ができるのか？
- iPhone/iPadからWindows Serverへのリモート接続
- AWS EC2 Windowsインスタンスへの接続
- オンプレミスのRDPサーバーへの接続
- 企業内のWindows仮想デスクトップへの接続

### 🎯 対象読者
- iOS開発の基礎知識がある方
- RDPクライアントアプリを作りたい方
- FreeRDPライブラリをiOSで使用したい方
- **プログラミング初心者でも、このガイドに従えば必ずビルドできます！**

---

## 📋 必須環境とツール

### 🖥️ ハードウェア要件
- **macOS搭載マシン**: Apple Silicon Mac（M1/M2/M3/M4）
- **⚠️ Intel Macは対応していません**
- メモリ: 8GB以上推奨
- ストレージ: 15GB以上の空き容量

### 💻 ソフトウェア要件
- **macOS**: 14.0（Sonoma）以上
- **Xcode**: 16.3 以上（App Storeから無料でダウンロード可能）
- **iOS実機**: iOS 16.0以上（RDP接続テスト用）

### 🛠️ 必須ツール一覧

#### 1. Command Line Tools
Xcodeとは別に必要です。
```bash
xcode-select --install
```
実行後、ダイアログに従ってインストールしてください。

#### 2. Homebrew（パッケージマネージャー）
各種開発ツールを簡単にインストールするために使用します。
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 3. 必要なツールをHomebrew経由でインストール
```bash
# Git（バージョン管理）
brew install git

# XcodeGen（プロジェクト自動生成）
brew install xcodegen

# CMake（ビルドシステム）
brew install cmake

# Ruby + CocoaPods（iOS依存管理）
brew install ruby
sudo gem install cocoapods
```

### 📚 使用技術スタック

---

## 🛠️ プロジェクトを支える技術スタック
このプロジェクトは、以下の主要なライブラリとツールによって構成されています。

- **FreeRDP**: RDPプロトコルのコアライブラリ。iOS向けに特別にクロスビルドして使用します。
- **OpenSSL**: 通信の暗号化に使われるライブラリ。これもiOS向けに静的ビルドします。
- **cJSON**: 軽量なJSONパーサー。FreeRDPのビルドに必要です。
- **R.swift**: 画像やStoryboardなどのリソースをタイプセーフに扱うためのツール。Swift Package Manager（SPM）経由で導入しています。
- **XcodeGen**: プロジェクト設定をコードで管理（`project.yml`）し、共同開発時のコンフリクトを減らします。

---

## 🚀 クイックスタート：ビルドから実行まで
このセクションでは、プロジェクトをあなたのマシンで動かすための全手順を解説します。

### ステップ1：リポジトリのクローン
まず、プロジェクトのソースコードをローカルにダウンロードします。

```bash
git clone <このリポジトリのURL>
cd FreeRDP-iOS-Sample
```

### ステップ2：依存ライブラリのビルドとプロジェクト設定
次に、メインのビルドスクリプトを実行します。このコマンド一つで、必要なライブラリのビルドからXcodeプロジェクトの生成まで、全てが自動的に行われます。

```bash
./build.sh build
```

**このスクリプトが実行すること：**
1.  **ツールの確認**: `cmake` や `xcodegen` がインストールされているかチェックします。
2.  **依存ライブラリのビルド**:
    - `OpenSSL`: iOS実機用とシミュレータ用の両方をビルドします。
    - `cJSON`: 同様に、両プラットフォーム向けにビルドします。
    - `FreeRDP`: 最も重要な部分です。iOS向けにクロスビルドし、必要な機能を有効化します。
3.  **Xcodeプロジェクト生成**: `project.yml` の設定に基づき、`xcodegen` を使って `MyRDPApp.xcodeproj` を生成します。
4.  **CocoaPodsセットアップ**: `pod install` を実行し、必要なPodライブラリを導入します。

### ステップ3：Xcodeでアプリを開き、実行する
ビルドが完了したら、生成された `.xcworkspace` ファイルをXcodeで開きます。

```bash
open iOSApp/MyRDPApp.xcworkspace
```

**Xcodeでの手順：**
1.  **ターゲットデバイスの選択**: Xcodeの上部にあるドロップダウンメニューから、接続しているiPhone実機、またはiOSシミュレータを選択します。
2.  **ビルド＆実行**: ▶（実行）ボタンをクリックしてアプリをビルドし、選択したデバイスにインストール・実行します。

> **⚠️ 重要：シミュレータに関する注意**
> RDP接続の大部分は実機でのみ正常に動作します。シミュレータはUIの確認など限定的な用途に留め、**接続テストは必ずiPhone実機で行ってください。**

---

## 📁 プロジェクト構成の詳細
プロジェクトの主要なファイルとディレクトリの役割を理解することで、カスタマイズや問題解決が容易になります。

```
FreeRDP-iOS-Sample/
├── build.sh                # メインのビルドスクリプト
├── scripts/                # 各ライブラリ用の個別ビルドスクリプト群
├── docs/                   # 設計資料や開発ログ
├── iOSApp/
│   ├── MyRDPApp/           # ★ アプリのメインソースコード
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   ├── LaunchScreen.storyboard
│   │   ├── Main.storyboard
│   │   ├── ViewController.swift
│   │   ├── MyRDPApp-Bridging-Header.h # Objective-CとSwiftの連携用ヘッダー
│   │   ├── Assets.xcassets/           # 画像やアイコンなどのリソース
│   │   │   ├── AppIcon.appiconset/
│   │   │   └── ...
│   │   ├── ConnectionList/            # 【接続先リスト画面】関連
│   │   │   ├── ConnectionList.storyboard
│   │   │   ├── ConnectionListViewController.swift
│   │   │   ├── ConnectionListViewController+Segue.swift
│   │   │   ├── ConnectionListCell.swift
│   │   │   └── ConnectionListCell.xib
│   │   ├── AddConnection/             # 【接続先追加画面】関連
│   │   │   ├── AddConnection.storyboard
│   │   │   └── AddConnectionViewController.swift
│   │   ├── RDPScreen/                 # 【RDP描画画面】関連
│   │   │   ├── RDPScreen.storyboard
│   │   │   ├── RDPScreenViewController.swift
│   │   │   ├── RDPScreenView.swift
│   │   │   └── RDPScreenView.xib
│   │   ├── RDP/                       # 【RDP処理コア】関連
│   │   │   ├── RDPConnection.swift
│   │   │   ├── RDPConnectionManager.swift
│   │   │   ├── FreeRDPBridge.h        # SwiftとFreeRDP(C)を繋ぐブリッジヘッダー
│   │   │   ├── FreeRDPBridge.m        # ブリッジの実装
│   │   │   ├── OpenSSLHelper.h
│   │   │   └── OpenSSLHelper.m
│   │   ├── Model/
│   │   │   └── CredentialStore.swift  # 認証情報管理
│   │   ├── Integration/
│   │   │   └── AWSIntegration.swift   # AWS連携（将来用）
│   │   └── Enum/
│   │       └── RDPConnectionError.swift # エラー定義
│   ├── Libraries/                     # ビルドされた静的ライブラリ(.a)が格納される
│   ├── project.yml                    # XcodeGenの設定ファイル
│   └── Package.swift                  # Swift Package Managerの設定ファイル
└── ...
```

---

## 📝 Xcode/XcodeGen/ライブラリ設定
- **Xcodeバージョン**: `project.yml`内で`iOS: "16.3"`のようにターゲットバージョンが明記されています。
- **XcodeGen**: プロジェクトの設定（ターゲット、依存関係、ビルド設定など）は全て`project.yml`で管理されています。Xcodeプロジェクトファイルを直接編集する代わりに、このファイルを修正し`xcodegen`を実行してください。
- **SwiftPM**: `R.swift`をSPMで導入しています。`Package.swift`で管理されています。
- **リンクされる主なライブラリ/フレームワーク**:
    - `libfreerdp3.a`, `libwinpr3.a` (FreeRDP)
    - `libcrypto.a`, `libssl.a` (OpenSSL)
    - `libcjson.a` (cJSON)
    - `Foundation`, `Security`, `CoreGraphics`などiOS標準フレームワーク
    - `RswiftLibrary` (SPM経由)

---

## 💡 アプリの基本的な使い方
1.  アプリを起動すると、接続先リストが表示されます。
2.  右上の「+」ボタンをタップして、新規接続先を追加します。
3.  ホスト名（IPアドレス）、ユーザー名、パスワードを入力し、保存します。
4.  リストから接続したい項目をタップすると、RDP接続が開始されます。

---

## 🔧 トラブルシューティング
- **ビルドに失敗する場合**:
    - まずは `clean.sh` を実行してみてください: `./build.sh clean && ./build.sh build`
    - Command Line Toolsが正しくインストールされているか確認してください。
    - `scripts/`内の各ビルドスクリプトのログ（`build/`ディレクトリに出力）を確認し、エラーメッセージを調査してください。
- **RDP接続ができない場合**:
    - **必ず実機で試っていますか？** シミュレータでは動作しません。
    - サーバーのIPアドレス、認証情報が正しいか再確認してください。
    - サーバー側のファイアウォール設定がRDP接続（ポート3389）を許可しているか確認してください。

---

## ⚠️ セキュリティに関する注意事項
- このプロジェクトは、レガシーな認証方式（MD4/RC4）を有効化してビルドしています。これは互換性を優先した設定であり、**現代のセキュリティ基準では非推奨**です。
- 実運用環境では、CredSSP/NLAやTLSなど、より強固な認証・暗号化方式へ移行することを強く推奨します。

---

## 🛠️ ビルドスクリプトの詳細解説
本プロジェクトの心臓部とも言える自動化スクリプト群です。

- `build.sh`: 全てのビルドプロセスを統括するメインスクリプト。引数（`build`, `clean`など）に応じて適切な処理を呼び出します。
- `scripts/build_freerdp.sh`: FreeRDP本体をiOS向けにクロスビルドします。アーキテクチャ（実機/シミュレータ）に応じた最適化や、機能の有効化/無効化など、複雑な設定を自動で行います。
- `scripts/build_openssl.sh`: OpenSSLをビルドします。
- `scripts/build_cjson.sh`: cJSONをビルドします。
- `clean.sh`, `config.sh`: クリーンアップや設定確認用の補助スクリプトです。

これらのスクリプトにより、開発環境のセットアップが大幅に簡略化され、誰が実行しても同じビルド結果を得られるようになっています。

---

## 📄 ライセンス
このプロジェクトは **MITライセンス** の下で公開されています。

---

## 🙏 謝辞
このプロジェクトは、以下の素晴らしいオープンソースプロジェクトのおかげで成り立っています。
- [FreeRDP](https://github.com/FreeRDP/FreeRDP)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [CocoaPods](https://cocoapods.org)
- [R.swift](https://github.com/mac-cain13/R.swift)

---
（このREADMEは2025年6月20日現在のプロジェクト構成・ビルドスクリプト・依存関係に基づき自動生成・加筆修正されました）
