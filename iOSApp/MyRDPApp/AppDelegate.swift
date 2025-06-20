//
//  AppDelegate.swift
//  MyRDPApp
//
//  Created on 2025/05/23.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties
    
    var window: UIWindow?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Application Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // アプリケーションの初期化
        setupApplication()
        
        // メインウィンドウの作成
        setupMainWindow()
        
        // AWS設定の初期化
        configureAWS()
        
        // OpenSSLの設定
         setupOpenSSL()
        
        // デバッグ設定
        #if DEBUG
        setupDebugConfiguration()
        #endif
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // アプリがアクティブでなくなる時の処理
        // RDP接続の一時停止など
        pauseRDPConnections()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // アプリがバックグラウンドに入る時の処理
        // 必要に応じてRDP接続を切断
        handleBackgroundTransition()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // アプリがフォアグラウンドに戻る時の処理
        // RDP接続の復旧など
        handleForegroundTransition()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // アプリがアクティブになった時の処理
        resumeRDPConnections()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // アプリが終了する時の処理
        cleanupApplication()
    }
    
    // MARK: - Setup Methods
    
    private func setupApplication() {
        // アプリケーション全体の設定
        debugPrint("Setting up MyRDPApp...")
        
        // ログ設定
        setupLogging()
        
        // クラッシュレポート設定（実際のプロジェクトで実装）
        // setupCrashReporting()
        
        // アナリティクス設定（実際のプロジェクトで実装）
        // setupAnalytics()
        
        debugPrint("Application setup completed")
    }
    
    private func setupMainWindow() {
        // メインウィンドウの作成 - Storyboardを使用
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Main.storyboardからUIStoryboardを作成
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        // 初期ビューコントローラを取得
        if let initialViewController = mainStoryboard.instantiateInitialViewController() {
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
            debugPrint("Main window setup completed with storyboard")
        } else {
            debugPrint("Failed to load initial view controller from Main.storyboard")
        }
    }
    
    private func configureAWS() {
        // AWS設定の初期化
        let awsIntegration = AWSIntegration.shared
        
        // 設定ファイルまたは環境変数から取得（実際の実装）
        let identityPoolId = getAWSIdentityPoolId()
        let region = getAWSRegion()
        
        if !identityPoolId.isEmpty && !region.isEmpty {
            awsIntegration.configure(with: identityPoolId, region: region)
            debugPrint("AWS configured successfully")
        } else {
            debugPrint("AWS configuration not found - will need to be configured in settings")
        }
    }
    
    private func setupLogging() {
        // ログ設定
        #if DEBUG
        debugPrint("Debug logging enabled")
        #else
        debugPrint("Release logging configuration")
        #endif
    }
    
    #if DEBUG
    private func setupDebugConfiguration() {
        // デバッグ用設定
        debugPrint("Setting up debug configuration...")
        
        // テスト認証情報の作成
        CredentialStore.shared.createTestCredentials()
        
        // デバッグ用FreeRDP設定
        // enableFreeRDPDebugLogging()
        
        debugPrint("Debug configuration completed")
    }
    #endif
    
    // MARK: - Background/Foreground Handling
    
    private func pauseRDPConnections() {
        // RDP接続の一時停止
        debugPrint("Pausing RDP connections...")
        
        // 実際の実装では、アクティブな接続を一時停止
        // RDPConnectionManager.shared.pauseAllConnections()
    }
    
    private func resumeRDPConnections() {
        // RDP接続の復旧
        debugPrint("Resuming RDP connections...")
        
        // 実際の実装では、一時停止された接続を復旧
        // RDPConnectionManager.shared.resumeAllConnections()
    }
    
    private func handleBackgroundTransition() {
        debugPrint("App entering background...")
        
        // バックグラウンドタスクの開始
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "RDPCleanup") { [weak self] in
            self?.cleanupBackgroundTask()
        }
        
        // 必要に応じてRDP接続を切断
        // disconnectAllRDPConnections()
    }
    
    private func handleForegroundTransition() {
        debugPrint("App entering foreground...")
        
        // バックグラウンドタスクの終了
        cleanupBackgroundTask()
        
        // 接続状態の確認と復旧
        // checkAndRestoreRDPConnections()
    }
    
    private func cleanupBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
    
    // MARK: - Configuration Helpers
    
    private func getAWSIdentityPoolId() -> String {
        // 実際の実装では、設定ファイルや環境変数から取得
        if let path = Bundle.main.path(forResource: "AWSConfig", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) as? [String: Any],
           let identityPoolId = config["IdentityPoolId"] as? String {
            return identityPoolId
        }
        
        // プレースホルダー
        return "YOUR_IDENTITY_POOL_ID"
    }
    
    private func getAWSRegion() -> String {
        // 実際の実装では、設定ファイルや環境変数から取得
        if let path = Bundle.main.path(forResource: "AWSConfig", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) as? [String: Any],
           let region = config["Region"] as? String {
            return region
        }
        
        // プレースホルダー
        return "YOUR_AWS_REGION"
    }
    
    // MARK: - Cleanup
    
    private func cleanupApplication() {
        debugPrint("Cleaning up application...")
        
        // RDP接続の切断
        // RDPConnectionManager.shared.disconnectAll()
        
        // リソースのクリーンアップ
        // cleanupResources()
        
        // 一時ファイルの削除
        // cleanupTemporaryFiles()
        
        debugPrint("Application cleanup completed")
    }
    
    // MARK: - Error Handling
    
    func handleApplicationError(_ error: Error) {
        debugPrint("Application error: \(error.localizedDescription)")
        
        // エラーログの記録
        // logError(error)
        
        // 必要に応じてクラッシュレポートの送信
        // sendCrashReport(error)
        
        // ユーザーへの通知（実際のUIKitプロジェクトで実装）
        /*
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: "エラーが発生しました",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            
            if let topViewController = self.getTopViewController() {
                topViewController.present(alertController, animated: true)
            }
        }
        */
    }
    
    // MARK: - Memory Warning
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        debugPrint("Received memory warning")
        
        // メモリ使用量の削減
        // clearImageCache()
        // releaseUnusedResources()
        
        // RDP接続の品質を下げる
        // reduceRDPQuality()
    }
    
    // MARK: - URL Handling
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // URL スキームの処理
        debugPrint("Opening URL: \(url)")
        
        // RDP接続URLの処理
        if url.scheme == "rdp" {
            return handleRDPURL(url)
        }
        
        return false
    }
    
    private func handleRDPURL(_ url: URL) -> Bool {
        // RDP URL形式: rdp://username:password@host:port
        guard let host = url.host else { return false }
        
        let port = url.port ?? 3389
        let username = url.user ?? ""
        let password = url.password ?? ""        
        debugPrint("Handling RDP URL - Host: \(host), Port: \(port), User: \(username)")
        
        // メインビューコントローラーに接続要求を送信
        // 実際の実装では適切なナビゲーション処理を行う
        
        return true
    }

    // MARK: - OpenSSL Setup
    private func setupOpenSSL() {
        // 初期化
        OpenSSLHelper.initializeOpenSSL()
        
        // MD4を強制登録
        OpenSSLHelper.forceMD4Registration()
        
        // 確認
        if OpenSSLHelper.isMD4Available() {
            print("✓ MD4 setup successful!")
        } else {
            print("✗ MD4 setup failed")
        }
    }

    private func testMD4DirectAccess() {
        print("\n=== Testing MD4 Direct Access ===")
        
        // EVP_get_digestbynameでテスト
        let md4 = EVP_get_digestbyname("MD4")
        if md4 != nil {
            print("✓ MD4 accessible via EVP_get_digestbyname")
            
            // 実際にハッシュ計算してみる
            var md = [UInt8](repeating: 0, count: Int(EVP_MAX_MD_SIZE))
            var md_len: UInt32 = 0
            let testString = "test"
            let data = testString.data(using: .utf8)!
            
            let result = data.withUnsafeBytes { bytes in
                EVP_Digest(
                    bytes.baseAddress,
                    data.count,
                    &md,
                    &md_len,
                    md4,
                    nil
                )
            }
            
            if result == 1 && md_len > 0 {
                let hash = md.prefix(Int(md_len)).map { String(format: "%02x", $0) }.joined()
                print("✓ MD4 hash of '\(testString)': \(hash)")
                // MD4("test") = db346d691d7acc4dc2625db19f9e3f52
            } else {
                print("✗ MD4 hash calculation failed")
            }
        } else {
            print("✗ MD4 not accessible")
        }
    }
}
