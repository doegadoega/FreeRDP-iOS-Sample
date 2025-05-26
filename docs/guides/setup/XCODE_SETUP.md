# Xcode プロジェクト作成ガイド

## 🎯 Xcodeプロジェクトの手動作成

既存のファイルを使ってXcodeプロジェクトを作成する手順です。

### 1. 新しいプロジェクトの作成

1. **Xcodeを起動**
2. **"Create a new Xcode project"** を選択
3. **iOS** → **App** を選択
4. プロジェクト設定:
   - **Product Name**: `MyRDPApp`
   - **Interface**: `Storyboard`
   - **Language**: `Swift`
   - **Bundle Identifier**: `com.example.MyRDPApp`
   - **Use Core Data**: チェックしない
   - **Include Tests**: チェックしない
5. **保存場所**: `FreeRDPiOSApp` フォルダを選択

### 2. 既存ファイルの追加

プロジェクト作成後、以下のファイルを追加します：

#### Swift ファイル
- `RDPConnectionManager.swift`
- `RDPScreenView.swift`
- `AWSIntegration.swift`
- `CredentialStore.swift`

#### Objective-C ファイル
- `FreeRDPBridge.h`
- `FreeRDPBridge.m`

#### リソースファイル
- `Main.storyboard` (既存のものと置き換え)
- `LaunchScreen.storyboard` (既存のものと置き換え)
- `Assets.xcassets` (既存のものと置き換え)
- `Info.plist` (既存のものと置き換え)

### 3. ファイル追加手順

1. **Xcodeのプロジェクトナビゲーター**で右クリック
2. **"Add Files to MyRDPApp"** を選択
3. `MyRDPApp` フォルダ内のファイルを選択
4. **"Copy items if needed"** をチェック
5. **"Add"** をクリック

### 4. Bridging Header の設定

1. **Project Settings** → **Build Settings**
2. **"Swift Compiler - General"** セクション
3. **"Objective-C Bridging Header"** に以下を設定:
   ```
   MyRDPApp/MyRDPApp-Bridging-Header.h
   ```

### 5. CocoaPods の設定

```bash
cd FreeRDPiOSApp
pod install
```

### 6. ワークスペースを開く

```bash
open MyRDPApp.xcworkspace
```

## 🚀 自動セットアップスクリプト

手動作成が面倒な場合は、以下のスクリプトを実行してください：

```bash
# プロジェクト作成スクリプト
./create_xcode_project.sh
```

## 📱 ビルド設定

### 必要な設定項目

1. **Development Team**: 自分の開発者アカウントを選択
2. **Bundle Identifier**: 一意の識別子に変更
3. **Deployment Target**: iOS 14.0以上

### フレームワークの追加

以下のフレームワークを追加してください：

- `Security.framework` (キーチェーン用)
- `Network.framework` (ネットワーク監視用)
- `LocalAuthentication.framework` (生体認証用)

### ライブラリパスの設定

**Build Settings** → **Library Search Paths** に以下を追加：
```
$(PROJECT_DIR)/libs
```

## 🔧 トラブルシューティング

### ビルドエラーが出る場合

1. **Clean Build Folder** (⌘+Shift+K)
2. **Derived Data** を削除
3. **Product** → **Clean Build Folder**

### CocoaPods エラー

```bash
pod deintegrate
pod install
```

### Bridging Header エラー

1. ファイルパスが正しいか確認
2. `MyRDPApp-Bridging-Header.h` が存在するか確認
3. Build Settings の設定を再確認

## 📋 完了チェックリスト

- [ ] Xcodeプロジェクトが作成された
- [ ] 全てのSwiftファイルが追加された
- [ ] Objective-Cファイルが追加された
- [ ] Bridging Headerが設定された
- [ ] CocoaPodsがインストールされた
- [ ] プロジェクトがビルドできる
- [ ] シミュレーターで実行できる

## 🎉 次のステップ

プロジェクトが正常に作成されたら：

1. **AWS設定の更新** (`AppDelegate.swift`)
2. **開発チームの設定**
3. **実機テスト**
4. **FreeRDPライブラリの統合**

詳細は `README.md` と `QUICK_START.md` を参照してください。
