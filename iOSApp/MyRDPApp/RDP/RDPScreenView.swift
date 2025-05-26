//
//  RDPScreenView.swift
//  MyRDPApp
//
//  Created on 2025/05/23.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

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
    
    private var imageView: UIImageView
    private var activityIndicator: UIActivityIndicatorView
    private var statusLabel: UILabel
    
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
        // UIコンポーネントの初期化
        imageView = UIImageView(frame: CGRect(origin: .zero, size: frame.size))
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        
        statusLabel = UILabel()
        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.isHidden = true
        
        super.init(frame: frame)
        
        // サブビューの追加
        addSubview(imageView)
        addSubview(activityIndicator)
        addSubview(statusLabel)
        
        // レイアウト設定
        imageView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),
            statusLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -40),
            statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
        
        // 初期状態の設定
        showDisconnected()
        
        // ジェスチャー認識の設定
        setupGestureRecognizers()
        
        debugPrint("RDPScreenView initialized")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
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
    
    private func convertPointToRemoteCoordinates(_ point: CGPoint) -> CGPoint {
        guard let image = imageView.image else { return point }
        
        let imageSize = image.size
        let viewSize = imageView.bounds.size
        
        // アスペクト比を考慮した座標変換
        let scaleX = imageSize.width / viewSize.width
        let scaleY = imageSize.height / viewSize.height
        
        return CGPoint(x: point.x * scaleX, y: point.y * scaleY)
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
}

// MARK: - ConnectionState

extension RDPScreenView {
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
    }
}
