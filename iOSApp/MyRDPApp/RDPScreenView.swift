//
//  RDPScreenView.swift
//  MyRDPApp
//
//  Created on 2025/05/23.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

import Foundation
import UIKit

protocol RDPScreenViewDelegate: AnyObject {
    func didTapScreen(at point: CGPoint)
    func didLongPressScreen(at point: CGPoint)
    func didPanScreen(from startPoint: CGPoint, to endPoint: CGPoint)
    func didPinchScreen(scale: CGFloat, at point: CGPoint)
    func didSwipeScreen(direction: UISwipeGestureRecognizer.Direction, at point: CGPoint)
}

class RDPScreenView: UIView {
    
    // MARK: - Properties
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .black
        }
    }
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = .white
        }
    }
    @IBOutlet weak var statusLabel: UILabel!
    
    private var lastImage: CGImage?
    private var connectionState: ConnectionState = .disconnected
    
    weak var delegate: RDPScreenViewDelegate?
    
    // Gesture recognizers
    private var tapGesture: UITapGestureRecognizer!
    private var longPressGesture: UILongPressGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    private var swipeGestures: [UISwipeGestureRecognizer] = []
    
    // Touch tracking
    private var lastTouchPoint: CGPoint = .zero
    private var isScrolling = false
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFromNib()
    }
    
    private func setupFromNib() {
        // Xibファイルからビューを読み込む
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "RDPScreenView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        // 初期設定
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .black
        
        // 画像表示用ビューの設定
        self.imageView = UIImageView(frame: bounds)
        self.imageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.imageView?.contentMode = .scaleAspectFit
        self.imageView?.backgroundColor = .black
        
        if let imageView = self.imageView {
            addSubview(imageView)
        }
        
        // 接続中表示用ラベルの設定
        statusLabel = UILabel(frame: bounds)
        statusLabel?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        statusLabel?.textAlignment = .center
        statusLabel?.textColor = .white
        statusLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        statusLabel?.text = "接続中..."
        statusLabel?.isHidden = true
        
        if let statusLabel = statusLabel {
            addSubview(statusLabel)
        }
        
        // ジェスチャー認識の設定
        setupGestureRecognizers()
    }
    
    func updateScreen(with image: CGImage) {
        lastImage = image
        imageView.image = UIImage(cgImage: image)
        
        if connectionState == .connecting {
            showConnected()
        }
    }
    
    func showConnecting() {
        connectionState = .connecting
        activityIndicator.startAnimating()
        showStatus("接続中...")
    }
    
    func showConnected() {
        connectionState = .connected
        activityIndicator.stopAnimating()
        hideStatus()
    }
    
    func showDisconnected() {
        connectionState = .disconnected
        activityIndicator.stopAnimating()
        imageView.image = nil
        showStatus("切断されました")
    }
    
    func showError(_ message: String) {
        connectionState = .disconnected
        activityIndicator.stopAnimating()
        showStatus("エラー: \(message)")
    }
    
    // MARK: - Private Methods
    
    private func showStatus(_ message: String) {
        statusLabel.text = "  \(message)  "
        statusLabel.isHidden = false
    }
    
    private func hideStatus() {
        statusLabel.isHidden = true
    }
    
    private func setupGestureRecognizers() {
        // タップジェスチャー
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        // ロングプレスジェスチャー（右クリック相当）
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        addGestureRecognizer(longPressGesture)
        
        // パンジェスチャー（ドラッグ）
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        // ピンチジェスチャー（ズーム）
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
        
        // スワイプジェスチャー
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        for direction in directions {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipeGesture.direction = direction
            addGestureRecognizer(swipeGesture)
        }
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        debugPrint("Tap at: \(location)")
        let convertedPoint = convertPointToRemoteCoordinates(location)
        delegate?.didTapScreen(at: convertedPoint)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let location = gesture.location(in: self)
            debugPrint("Long press at: \(location)")
            let convertedPoint = convertPointToRemoteCoordinates(location)
            delegate?.didLongPressScreen(at: convertedPoint)
            
            // ハプティックフィードバック
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            lastTouchPoint = gesture.location(in: self)
            isScrolling = false
        case .changed:
            let currentPoint = gesture.location(in: self)
            if !isScrolling {
                let startPoint = convertPointToRemoteCoordinates(lastTouchPoint)
                let endPoint = convertPointToRemoteCoordinates(currentPoint)
                delegate?.didPanScreen(from: startPoint, to: endPoint)
            }
        case .ended, .cancelled:
            isScrolling = false
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            let location = gesture.location(in: self)
            debugPrint("Pinch with scale \(gesture.scale) at: \(location)")
            let convertedPoint = convertPointToRemoteCoordinates(location)
            delegate?.didPinchScreen(scale: gesture.scale, at: convertedPoint)
            gesture.scale = 1.0
        }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let location = gesture.location(in: self)
        let direction = gesture.direction
        
        var directionString = ""
        switch direction {
        case .up:
            directionString = "up"
        case .down:
            directionString = "down"
        case .left:
            directionString = "left"
        case .right:
            directionString = "right"
        default:
            directionString = "unknown"
        }
        
        debugPrint("Swipe \(directionString) at: \(location)")
        let convertedPoint = convertPointToRemoteCoordinates(location)
        delegate?.didSwipeScreen(direction: direction, at: convertedPoint)
    }
    
    // MARK: - Coordinate Conversion
    
    // タッチ座標をリモート座標系に変換
    func convertPointToRemoteCoordinates(_ point: CGPoint) -> CGPoint {
        guard let image = lastImage,
              let size = imageView.image?.size else {
            return point
        }
        
        // UIImageViewの実際の表示領域を計算
        let viewFrame = imageView.frame
        
        // 画像のアスペクト比に基づいて実際の表示サイズを計算
        let aspectRatio = size.width / size.height
        let viewAspectRatio = viewFrame.width / viewFrame.height
        
        var imageRect = CGRect.zero
        
        if aspectRatio > viewAspectRatio {
            // 幅に合わせる
            let scaledHeight = viewFrame.width / aspectRatio
            let yOffset = (viewFrame.height - scaledHeight) / 2
            imageRect = CGRect(x: 0, y: yOffset, width: viewFrame.width, height: scaledHeight)
        } else {
            // 高さに合わせる
            let scaledWidth = viewFrame.height * aspectRatio
            let xOffset = (viewFrame.width - scaledWidth) / 2
            imageRect = CGRect(x: xOffset, y: 0, width: scaledWidth, height: viewFrame.height)
        }
        
        // タッチ座標を画像内の座標に変換
        let x = ((point.x - imageRect.origin.x) / imageRect.width) * CGFloat(image.width)
        let y = ((point.y - imageRect.origin.y) / imageRect.height) * CGFloat(image.height)
        
        return CGPoint(x: max(0, min(CGFloat(image.width), x)),
                      y: max(0, min(CGFloat(image.height), y)))
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 画面回転時の処理
        if let image = imageView.image {
            updateImageViewConstraints(for: image.size)
        }
    }
    
    private func updateImageViewConstraints(for imageSize: CGSize) {
        let viewSize = imageView.bounds.size
        let scaleX = viewSize.width / imageSize.width
        let scaleY = viewSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        
        imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    
    func toggleKeyboard() {
        // 実装例: キーボード表示/非表示の切り替え（必要に応じてカスタマイズ）
        // ここでは何もしないダミー実装
    }
    
    func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        // 実装例: ピンチイン/アウトの処理（必要に応じてカスタマイズ）
        // ここでは何もしないダミー実装
    }
    
    func resetZoom() {
        // 実装例: ズームリセット処理（必要に応じてカスタマイズ）
        // ここでは何もしないダミー実装
    }
    
    // 引数ラベルを修正
    func updateScreen(_ image: CGImage) {
        updateScreen(with: image)
    }
}

// MARK: - ConnectionState

extension RDPScreenView {
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
    }
}
