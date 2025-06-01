//
//  ViewController.swift
//  MyRDPApp
//
//  Created on 2025/05/23.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    private var rdpConnectionManager: RDPConnectionManager?
    private var rdpScreenView: RDPScreenView?
    private var connectionAlertController: UIAlertController?
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupRDPComponents()
        
        debugPrint("ViewController loaded")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        debugPrint("ViewController will appear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        debugPrint("ViewController did appear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 画面が非表示になる際に接続を切断
        rdpConnectionManager?.disconnect()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "MyRDP App"
        
        // ナビゲーションバーの設定
        let connectButton = UIBarButtonItem(
            title: "接続",
            style: .plain,
            target: self,
            action: #selector(showConnectionDialog)
        )
        
        navigationItem.rightBarButtonItems = [connectButton]
        
        // RDP表示用ビューの設定
        rdpScreenView = RDPScreenView(frame: view.bounds)
        if let rdpScreenView = rdpScreenView {
            rdpScreenView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            rdpScreenView.delegate = self
            view.addSubview(rdpScreenView)
        }
        
        debugPrint("UI setup completed")
    }
    
    private func setupRDPComponents() {
        // RDP接続マネージャーの初期化
        rdpConnectionManager = RDPConnectionManager()
        rdpConnectionManager?.delegate = self
        
        debugPrint("RDP components setup completed")
    }
    
    // MARK: - Action Methods
    
    @objc private func showConnectionDialog() {
        let alertController = UIAlertController(
            title: "RDP接続",
            message: "接続先を入力してください",
            preferredStyle: .alert
        )
        
        // 既存のアラートコントローラーを保持
        connectionAlertController = alertController
        
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "ホスト名（例: example.com）"
            textField.delegate = self
        }
        
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "ポート（例: 3389）"
            textField.keyboardType = .numberPad
            textField.text = "3389"
            textField.delegate = self
        }
        
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "ユーザー名"
            textField.delegate = self
        }
        
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "パスワード"
            textField.isSecureTextEntry = true
            textField.delegate = self
        }
        
        let connectAction = UIAlertAction(title: "接続", style: .default) { [weak self] _ in
            self?.handleConnectionAction(alertController)
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { [weak self] _ in
            self?.connectionAlertController = nil
        }
        
        alertController.addAction(connectAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func handleConnectionAction(_ alertController: UIAlertController) {
        guard let hostname = alertController.textFields?[0].text,
              let portText = alertController.textFields?[1].text,
              let username = alertController.textFields?[2].text,
              let password = alertController.textFields?[3].text,
              !hostname.isEmpty,
              !username.isEmpty else {
            showErrorAlert(message: "接続情報が不完全です")
            return
        }
        
        let port = Int(portText) ?? 3389
        
        // 接続処理開始前にアラートをクリア
        connectionAlertController = nil
        
        connectToRDP(hostname: hostname, port: port, username: username, password: password)
    }
    
    private func connectToRDP(hostname: String, port: Int, username: String, password: String) {
        debugPrint("Connecting to RDP - Host: \(hostname), Port: \(port), User: \(username)")
        
        // 接続処理
        rdpConnectionManager?.connect(to: hostname, port: port, username: username, password: password)
    }
    
    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(
            title: "エラー",
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
    
    // MARK: - EC2 Connection Methods
    
    @objc private func showEC2ConnectionOptions() {
        let alertController = UIAlertController(
            title: "EC2インスタンス選択",
            message: "接続先のEC2インスタンスを選択してください",
            preferredStyle: .actionSheet
        )
        
        // iPad用の設定
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?[1]
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func connectToEC2(host: String, username: String, password: String) {
        // RDP標準ポート
        let port = 3389
        
        debugPrint("Connecting to EC2 - Host: \(host), User: \(username)")
        
        // 接続開始前に接続中表示
        rdpScreenView?.showConnecting()
        
        // RDP接続開始
        rdpConnectionManager?.connect(to: host, port: port, username: username, password: password)
    }
}

// MARK: - RDPConnectionManagerDelegate

extension ViewController: RDPConnectionManagerDelegate {
    
    func connectionManager(_ manager: RDPConnectionManager, didUpdateScreen image: CGImage) {
        // 画面更新時の処理
        rdpScreenView?.updateScreen(with: image)
    }
    
    func connectionManager(_ manager: RDPConnectionManager, didChangeState connected: Bool) {
        // 接続状態変更時の処理
        if connected {
            debugPrint("RDP connection established")
            title = "接続中"
        } else {
            debugPrint("RDP connection closed")
            title = "切断"
        }
    }
    
    func connectionManager(_ manager: RDPConnectionManager, didEncounterError error: Error) {
        // エラー発生時の処理
        debugPrint("RDP connection error: \(error.localizedDescription)")
        showErrorAlert(message: "接続エラー: \(error.localizedDescription)")
    }
}

// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // ポート番号の入力制限
        if textField.keyboardType == .numberPad {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
}

// MARK: - RDPScreenViewDelegate

extension ViewController: RDPScreenViewDelegate {
    
    func didTapScreen(at point: CGPoint) {
        // シングルタップでは左クリック
        let buttonNumber = 1 // 左クリック
        
        // 左クリックの押下と解放をシミュレート
        rdpConnectionManager?.sendMouseEvent(at: point, isDown: true, button: buttonNumber)
        
        // 少し遅延してマウスアップ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.rdpConnectionManager?.sendMouseEvent(at: point, isDown: false, button: buttonNumber)
        }
    }
    
    func didLongPressScreen(at point: CGPoint) {
        // 長押しは右クリック
        let buttonNumber = 2 // 右クリック
        
        rdpConnectionManager?.sendMouseEvent(at: point, isDown: true, button: buttonNumber)
        
        // 少し遅延してマウスアップ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.rdpConnectionManager?.sendMouseEvent(at: point, isDown: false, button: buttonNumber)
        }
    }
    
    func didPanScreen(from startPoint: CGPoint, to endPoint: CGPoint) {
        // パンジェスチャーをドラッグ操作として扱う
        let buttonNumber = 1 // 左クリック
        
        // マウスダウン
        rdpConnectionManager?.sendMouseEvent(at: startPoint, isDown: true, button: buttonNumber)
        
        // マウス移動
        rdpConnectionManager?.sendMouseEvent(at: endPoint, isDown: true, button: buttonNumber)
        
        // マウスアップ
        rdpConnectionManager?.sendMouseEvent(at: endPoint, isDown: false, button: buttonNumber)
    }
    
    func didPinchScreen(scale: CGFloat, at point: CGPoint) {
        // ピンチジェスチャーを拡大/縮小操作として扱う
        let delta = (scale - 1.0) * 10.0
        
        // スクロールイベントとして扱う
        rdpConnectionManager?.sendScrollEvent(at: point, delta: delta)
    }
    
    func didSwipeScreen(direction: UISwipeGestureRecognizer.Direction, at point: CGPoint) {
        // スワイプジェスチャーをスクロール操作として扱う
        
        // 方向に応じてデルタ値を設定
        var delta: CGFloat = 0
        
        switch direction {
        case .up:
            delta = 5.0
        case .down:
            delta = -5.0
        case .left, .right:
            // 左右スワイプは横スクロールになるが、ここでは単純化のため縦スクロールとして扱う
            delta = direction == .left ? -5.0 : 5.0
        default:
            break
        }
        
        // スクロールイベントとして扱う
        rdpConnectionManager?.sendScrollEvent(at: point, delta: delta)
    }
}
