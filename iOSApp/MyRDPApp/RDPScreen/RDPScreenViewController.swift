import Foundation
import UIKit

class RDPScreenViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var rdpScreenView: RDPScreenView! // UIViewからRDPScreenViewに型を変更
    
    // MARK: - Properties
    var connection: RDPConnection?
    private var rdpConnectionManager: RDPConnectionManager?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRDPComponents()
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
        rdpScreenView.delegate = self // RDPScreenViewDelegateを設定
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
        
//        if gesture.state == .began {
//            lastPanPoint = point
//        } else if gesture.state == .changed || gesture.state == .ended {
//            guard let startPoint = lastPanPoint else { return }
//            didPanScreen(from: startPoint, to: point)
//            lastPanPoint = point
//        }
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
        guard let connection = connection else {
            return
        }
        
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

// MARK: - RDPScreenViewDelegate
extension RDPScreenViewController: RDPScreenViewDelegate {
    func didTapScreen(at point: CGPoint) {
        rdpConnectionManager?.sendMouseEvent(at: point, isDown: true, button: 1)
        // 少し遅延して離す
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.rdpConnectionManager?.sendMouseEvent(at: point, isDown: false, button: 1)
        }
    }
    
    func didLongPressScreen(at point: CGPoint) {
        rdpConnectionManager?.sendMouseEvent(at: point, isDown: true, button: 3) // 右クリック
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.rdpConnectionManager?.sendMouseEvent(at: point, isDown: false, button: 3)
        }
    }
    
    func didPanScreen(from startPoint: CGPoint, to endPoint: CGPoint) {
        rdpConnectionManager?.sendMouseEvent(at: endPoint, isDown: true, button: 1)
    }
    
    func didPinchScreen(scale: CGFloat, at point: CGPoint) {
        // スクロールとして処理
        let scrollDelta = (scale - 1.0) * 10.0
        rdpConnectionManager?.sendScrollEvent(at: point, delta: scrollDelta)
    }
    
    func didSwipeScreen(direction: UISwipeGestureRecognizer.Direction, at point: CGPoint) {
        var delta: CGFloat = 0
        
        switch direction {
        case .up:
            delta = 10
        case .down:
            delta = -10
        case .left, .right:
            // 横スクロールは必要に応じて実装
            return
        default:
            return
        }
        
        rdpConnectionManager?.sendScrollEvent(at: point, delta: delta)
    }
}

// MARK: - RDPConnectionManagerDelegate
extension RDPScreenViewController: RDPConnectionManagerDelegate {
    func connectionManager(_ manager: RDPConnectionManager, didUpdateScreen image: CGImage) {
        rdpScreenView.updateScreen(image) // RDPScreenViewの画面更新メソッドを使用
    }
    
    func connectionManager(_ manager: RDPConnectionManager, didChangeState connected: Bool) {
        if connected {
            rdpScreenView.showConnected() // 接続状態表示
        } else {
            rdpScreenView.showDisconnected() // 切断状態表示
        }
    }
    
    func connectionManager(_ manager: RDPConnectionManager, didEncounterError error: Error) {
        rdpScreenView.showError(error.localizedDescription) // エラー表示
    }
}
