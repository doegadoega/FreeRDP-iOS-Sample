import Foundation
import UIKit

class RDPScreenViewController: UIViewController {
    
    // MARK: - Outlets
    // 保存用の変数
    private var lastPanPoint: CGPoint?
    
    @IBOutlet weak var rdpScreenView: UIView!
    
    // MARK: - Properties
    
    var connection: RDPConnection?
    private var rdpConnectionManager: RDPConnectionManager?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRDPComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        connectToRDP()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        rdpConnectionManager?.disconnect()
    }
    
    // MARK: - Setup Methods
    
    private func setupRDPComponents() {
        // RDP接続マネージャーの初期化
        rdpConnectionManager = RDPConnectionManager.shared
        rdpConnectionManager?.delegate = self
        
        // RDPScreenViewの設定
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        // タップジェスチャー
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        rdpScreenView.addGestureRecognizer(tapGesture)
        
        // 長押しジェスチャー
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        rdpScreenView.addGestureRecognizer(longPressGesture)
        
        // パンジェスチャー
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        rdpScreenView.addGestureRecognizer(panGesture)
        
        // ピンチジェスチャー
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        rdpScreenView.addGestureRecognizer(pinchGesture)
        
        // スワイプジェスチャー（上下左右）
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeUp.direction = .up
        rdpScreenView.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeDown.direction = .down
        rdpScreenView.addGestureRecognizer(swipeDown)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        rdpScreenView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        rdpScreenView.addGestureRecognizer(swipeRight)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: rdpScreenView)
        didTapScreen(at: point)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: rdpScreenView)
            didLongPressScreen(at: point)
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: rdpScreenView)
        
        if gesture.state == .began {
            lastPanPoint = point
        } else if gesture.state == .changed || gesture.state == .ended {
            guard let startPoint = lastPanPoint else { return }
            didPanScreen(from: startPoint, to: point)
            lastPanPoint = point
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let point = gesture.location(in: rdpScreenView)
        didPinchScreen(scale: gesture.scale, at: point)
        gesture.scale = 1.0 // リセット
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let point = gesture.location(in: rdpScreenView)
        didSwipeScreen(direction: gesture.direction, at: point)
    }
    
    private func connectToRDP() {
        guard let connection = connection else { return }
        
        // 接続情報を更新
        rdpConnectionManager?.connect(
            to: connection.host,
            port: connection.port,
            username: connection.username,
            password: connection.password ?? ""
        )
        
        // 接続日時を更新
        var updatedConnection = connection
        updatedConnection.lastConnected = Date()
        RDPConnectionManager.shared.updateConnection(updatedConnection)
        
        // タイトル更新
        title = connection.name
    }
    
    // MARK: - Actions
    
    @IBAction func closeButtonTapped() {
        rdpConnectionManager?.disconnect()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func toggleKeyboard() {
        // キーボードの表示/非表示を切り替え
        if view.endEditing(true) {
            // キーボードが表示されていた場合は非表示に
        } else {
            // キーボードが非表示だった場合は表示
            let textField = UITextField()
            textField.inputAccessoryView = createKeyboardToolbar()
            view.addSubview(textField)
            textField.becomeFirstResponder()
            textField.removeFromSuperview()
        }
    }
    
    private func createKeyboardToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.items = [flexSpace, doneButton]
        return toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - RDPConnectionManagerDelegate

extension RDPScreenViewController: RDPConnectionManagerDelegate {
    
    func connectionManager(_ manager: RDPConnectionManager, didUpdateScreen image: CGImage) {
        // 画面更新時の処理
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 既存のイメージビューを探す
            let imageView: UIImageView
            if let existingImageView = self.rdpScreenView.subviews.first as? UIImageView {
                imageView = existingImageView
            } else {
                // 新しいイメージビューを作成
                imageView = UIImageView(frame: self.rdpScreenView.bounds)
                imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                imageView.contentMode = .scaleAspectFit
                self.rdpScreenView.addSubview(imageView)
            }
            
            // イメージを設定
            imageView.image = UIImage(cgImage: image)
        }
    }
    
    func connectionManager(_ manager: RDPConnectionManager, didChangeState connected: Bool) {
        // 接続状態変更時の処理
        DispatchQueue.main.async { [weak self] in
            if !connected {
                // 接続が切断された場合は前の画面に戻る
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func connectionManager(_ manager: RDPConnectionManager, didEncounterError error: Error) {
        // エラー発生時の処理
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alertController = UIAlertController(
                title: "エラー",
                message: "接続エラー: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.navigationController?.popViewController(animated: true)
            }
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true)
        }
    }
}

// MARK: - ジェスチャーハンドリング

extension RDPScreenViewController {
    
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
