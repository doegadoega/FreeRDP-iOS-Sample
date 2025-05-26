# 📱 FreeRDP iOS App - ステップバイステップガイド

## 🎯 完全セットアップ手順

このガイドに従って、FreeRDP iOSアプリを最初から最後まで作成できます。

### ステップ 1: 前提条件の確認

```bash
# 現在のディレクトリを確認
pwd
# 出力例: /Users/username/Desktop/FreeRDPiOSApp

# Xcodeがインストールされているか確認
xcodebuild -version
# 出力例: Xcode 16.3
```

### ステップ 2: プロジェクト作成の準備

```bash
# プロジェクト作成スクリプトを実行
./create_xcode_project.sh create
```

このコマンドを実行すると、以下の情報が表示されます：
- 現在のディレクトリパス
- Xcodeで作成すべきプロジェクトの設定

### ステップ 3: Xcodeでプロジェクト作成

1. **Xcodeを起動**
   ```bash
   open /Applications/Xcode.app
   ```

2. **新規プロジェクト作成**
   - "Create a new Xcode project" をクリック
   - **iOS** タブを選択
   - **App** を選択して "Next"

3. **プロジェクト設定**
   ```
   Product Name: MyRDPApp
   Team: (あなたの開発チーム)
   Organization Identifier: com.example.MyRDPApp
   Bundle Identifier: com.example.MyRDPApp (自動生成)
   Language: Swift
   Interface: Storyboard
   Use Core Data: チェックしない
   Include Tests: チェックしない
   ```

4. **保存場所の選択**
   - **重要**: `FreeRDPiOSApp` フォルダを選択
   - "Create" をクリック

### ステップ 4: プロジェクトセットアップ

Xcodeでプロジェクトが作成されたら、ターミナルに戻って：

```bash
# セットアップスクリプトを実行
./create_xcode_project.sh setup
```

このコマンドが以下を自動実行します：
- プロジェクト構造の確認
- CocoaPods依存関係のインストール
- プロジェクトビルドのテスト

### ステップ 5: ファイルの追加と設定

#### 5.1 既存ファイルの置き換え

Xcodeで以下の操作を行います：

1. **AppDelegate.swift の置き換え**
   - プロジェクトナビゲーターで `AppDelegate.swift` を削除
   - `MyRDPApp/AppDelegate.swift` をドラッグ&ドロップで追加

2. **ViewController.swift の置き換え**
   - 既存の `ViewController.swift` を削除
   - `MyRDPApp/ViewController.swift` を追加

3. **Storyboard の置き換え**
   - `Main.storyboard` を削除
   - `Main.storyboard` を追加
   - `LaunchScreen.storyboard` を削除
   - `MyRDPApp/LaunchScreen.storyboard` を追加

4. **Assets の置き換え**
   - `Assets.xcassets` を削除
   - `MyRDPApp/Assets.xcassets` を追加

#### 5.2 新しいファイルの追加

以下のファイルをプロジェクトに追加：

```
MyRDPApp/RDPConnectionManager.swift
MyRDPApp/RDPScreenView.swift
MyRDPApp/AWSIntegration.swift
MyRDPApp/CredentialStore.swift
MyRDPApp/FreeRDPBridge.h
MyRDPApp/FreeRDPBridge.m
MyRDPApp/MyRDPApp-Bridging-Header.h
```

**追加方法**:
1. プロジェクトナビゲーターで右クリック
2. "Add Files to MyRDPApp" を選択
3. ファイルを選択して "Add"

#### 5.3 Bridging Header の設定

1. **Project Settings** を開く
2. **Build Settings** タブ
3. **Swift Compiler - General** セクション
4. **Objective-C Bridging Header** に設定:
   ```
   MyRDPApp/MyRDPApp-Bridging-Header.h
   ```

### ステップ 6: ワークスペースを開く

```bash
# CocoaPodsワークスペースを開く
open MyRDPApp.xcworkspace
```

**重要**: 今後は `.xcworkspace` ファイルを使用してください。

### ステップ 7: ビルド設定

#### 7.1 開発チームの設定

1. **Project Settings** → **Signing & Capabilities**
2. **Team** で自分の開発者アカウントを選択
3. **Bundle Identifier** を一意のものに変更（例: `com.yourname.MyRDPApp`）

#### 7.2 フレームワークの追加

**Build Phases** → **Link Binary With Libraries** で以下を追加：
- `Security.framework`
- `Network.framework`
- `LocalAuthentication.framework`

### ステップ 8: 初回ビルドテスト

```bash
# プロジェクトをビルドしてテスト
./create_xcode_project.sh verify
```

または、Xcodeで：
1. **Product** → **Build** (⌘+B)
2. エラーがないことを確認

### ステップ 9: シミュレーターでの実行

1. **Scheme** で "MyRDPApp" を選択
2. **Destination** で iPhone 15 Pro シミュレーターを選択
3. **Run** ボタン (▶️) をクリック

### ステップ 10: AWS設定（オプション）

実際のAWS接続をテストする場合：

1. **AWS Cognito** でアイデンティティプールを作成
2. `AppDelegate.swift` の以下を更新：
   ```swift
   private func getAWSIdentityPoolId() -> String {
       return "YOUR_ACTUAL_IDENTITY_POOL_ID"
   }
   ```

## 🔧 トラブルシューティング

### よくある問題と解決策

#### 1. ビルドエラー: "No such module 'AWSCore'"

**解決策**:
```bash
pod install
# Xcodeを再起動
open MyRDPApp.xcworkspace
```

#### 2. Bridging Header エラー

**解決策**:
1. ファイルパスを確認: `MyRDPApp/MyRDPApp-Bridging-Header.h`
2. Build Settings で正しく設定されているか確認

#### 3. シミュレーターで起動しない

**解決策**:
1. **Product** → **Clean Build Folder** (⌘+Shift+K)
2. 再ビルド

#### 4. CocoaPods エラー

**解決策**:
```bash
pod deintegrate
pod install
```

## 📋 完了チェックリスト

- [ ] Xcodeプロジェクトが作成された
- [ ] 全てのソースファイルが追加された
- [ ] Bridging Headerが設定された
- [ ] CocoaPodsがインストールされた
- [ ] プロジェクトがビルドできる
- [ ] iPhone 15 Pro シミュレーターで実行できる
- [ ] 開発チームが設定された

## 🎉 次のステップ

プロジェクトが正常に動作したら：

1. **FreeRDPライブラリのビルド**:
   ```bash
   ./build.sh build
   ```

2. **実機でのテスト**

3. **AWS EC2インスタンスとの接続テスト**

4. **カスタマイズと機能追加**

## 📞 サポート

問題が発生した場合：
- `README.md` - 詳細技術ドキュメント
- `XCODE_SETUP.md` - Xcode設定詳細
- `QUICK_START.md` - 高速セットアップ
- `PROJECT_SUMMARY.md` - プロジェクト概要
