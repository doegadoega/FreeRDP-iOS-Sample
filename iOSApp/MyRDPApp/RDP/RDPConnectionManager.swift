//
//  RDPConnectionManager.swift
//  MyRDPApp
//
//  Created on 2025/05/23.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

import Foundation
import UIKit
import Network

// MARK: - RDPConnectionManagerDelegate

protocol RDPConnectionManagerDelegate: AnyObject {
    func connectionManager(_ manager: RDPConnectionManager, didUpdateScreen image: CGImage)
    func connectionManager(_ manager: RDPConnectionManager, didChangeState connected: Bool)
    func connectionManager(_ manager: RDPConnectionManager, didEncounterError error: Error)
}

// MARK: - RDPConnectionManager

class RDPConnectionManager {

    weak var delegate: RDPConnectionManagerDelegate?
    
    static let shared = RDPConnectionManager()
    private let connectionsKey = "savedRDPConnections"
    
    // MARK: - Properties
    private var bridge: FreeRDPBridge
    private var isConnected: Bool = false
    private var isConnecting: Bool = false
    
    private var hostname: String = ""
    private var port: Int = 3389
    private var username: String = ""
    private var password: String = ""
    private var domain: String = ""
    
    private var networkMonitor: NWPathMonitor?
    private var isMonitoringNetwork = false
    
    // Performance monitoring
    private var lastUpdateTime = Date()
    private let maxFrameRate: Double = 30.0 // FPS
    private var frameCount = 0
    private var performanceTimer: Timer?
    
    private var connectionThread: Thread?

    var connections: [RDPConnection] {
        get {
            guard let data = UserDefaults.standard.data(forKey: connectionsKey),
                  let connections = try? JSONDecoder().decode([RDPConnection].self, from: data) else {
                return []
            }
            return connections
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: connectionsKey)
            }
        }
    }
    
    func addConnection(_ connection: RDPConnection) {
        var currentConnections = connections
        currentConnections.append(connection)
        connections = currentConnections
    }
    
    func updateConnection(_ connection: RDPConnection) {
        var currentConnections = connections
        if let index = currentConnections.firstIndex(where: { $0.id == connection.id }) {
            currentConnections[index] = connection
            connections = currentConnections
        }
    }
    
    func deleteConnection(withId id: String) {
        var currentConnections = connections
        currentConnections.removeAll { $0.id == id }
        connections = currentConnections
    }
    
    func getConnection(withId id: String) -> RDPConnection? {
        return connections.first { $0.id == id }
    }
    
    // 接続情報を保存するメソッド
    func saveConnection(_ connection: RDPConnection) {
        // 既存の接続リストを取得
        var currentConnections = connections
        
        // 既に同じIDが存在する場合は更新、なければ追加
        if let index = currentConnections.firstIndex(where: { $0.id == connection.id }) {
            currentConnections[index] = connection
        } else {
            currentConnections.append(connection)
        }
        
        // 接続リストを保存（connectionsプロパティを使用）
        connections = currentConnections
    }
    
    // 接続リストを取得するメソッド
    func getConnections() -> [RDPConnection] {
        return connections
    }
    
    
    // MARK: - Initialization
    
    init() {
        bridge = FreeRDPBridge()
        setupBridgeCallbacks()
        debugPrint("RDPConnectionManager initialized")
        startNetworkMonitoring()
        
        // TODO: 初回起動時のみデフォルトのEC2接続情報を追加
        addDefaultConnectionIfNeeded()
    }
    
    // EC2のデフォルト接続先を追加
    private func addDefaultConnectionIfNeeded() {
        // 既存の接続情報がない場合のみデフォルト接続を追加
        if connections.isEmpty {

        }
    }
    
    deinit {
        stopNetworkMonitoring()
        performanceTimer?.invalidate()
        disconnect()
        debugPrint("RDPConnectionManager deinitialized")
    }
    
    // MARK: - Connection Management
    
    func connect(to host: String, port: Int, username: String, password: String, domain: String = "") {
        // 既存の接続を切断
        disconnect()
        
        // 接続情報を保存
        self.hostname = host
        self.port = port
        self.username = username
        self.password = password
        self.domain = domain
        
        // 接続状態を更新
        isConnecting = true
        
        // FreeRDPBridgeを使用して接続
        let success = bridge.connect(toHost: host, port: Int32(port), username: username, password: password, domain: domain.isEmpty ? nil : domain)
        
        if !success {
            isConnecting = false
            let error = RDPConnectionError.connectionFailed
            delegate?.connectionManager(self, didEncounterError: error)
        }
    }
    
    func disconnect() {
        // 接続状態のリセット
        isConnected = false
        
        // 接続スレッドの終了
        if let thread = connectionThread, thread.isExecuting {
            thread.cancel()
            
            // スレッドの終了を待機
            let deadline = Date().addingTimeInterval(2.0)
            while thread.isExecuting && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        
        connectionThread = nil
    }
    
    // MARK: - Input Handling
    
    func sendMouseEvent(at point: CGPoint, isDown: Bool, button: Int) {
        guard isConnected
        else {
            return
        }
        bridge.sendMouseEvent(point, isDown: isDown, button: Int32(button))
    }
    
    func sendKeyEvent(_ keyCode: Int, isDown: Bool) {
        guard isConnected
        else {
            return
        }
        bridge.sendKeyEvent(Int32(keyCode), isDown: isDown)
    }
    
    func sendScrollEvent(at point: CGPoint, delta: CGFloat) {
        guard isConnected
        else {
            return
        }
        bridge.sendScrollEvent(point, delta: delta)
    }
    
    // MARK: - Configuration
    
    func setScreenSize(_ size: CGSize) {
        bridge.setScreenSize(size)
    }
    
    func setColorDepth(_ depth: Int) {
        bridge.setColorDepth(Int32(depth))
    }
    
    func setCompressionEnabled(_ enabled: Bool) {
        bridge.setCompressionEnabled(enabled)
    }
    
    func setSecurityLevel(_ level: Int) {
        bridge.setSecurityLevel(Int32(level))
    }
    
    func enableDebugLogging(_ enabled: Bool) {
        bridge.enableDebugLogging(enabled)
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        guard !isMonitoringNetwork else { return }
        
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkPathUpdate(path)
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor?.start(queue: queue)
        isMonitoringNetwork = true
    }
    
    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
        isMonitoringNetwork = false
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        switch path.status {
        case .satisfied:
            if path.isExpensive {
                // セルラー接続の場合は品質を下げる
                setLowQualityMode()
            } else {
                // Wi-Fi接続の場合は高品質モード
                setHighQualityMode()
            }
        case .unsatisfied:
            // ネットワーク接続なし
            if isConnected {
                disconnect()
                let error = NSError(
                    domain: "RDPConnectionManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Network connection lost"]
                )
                delegate?.connectionManager(self, didEncounterError: error)
            }
        case .requiresConnection:
            // 接続が必要
            break
        @unknown default:
            break
        }
    }
    
    private func setHighQualityMode() {
        bridge.setColorDepth(32)
        bridge.setCompressionEnabled(false)
        print("Switched to high quality mode")
    }
    
    private func setLowQualityMode() {
        bridge.setColorDepth(16)
        bridge.setCompressionEnabled(true)
        print("Switched to low quality mode")
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.logPerformanceMetrics()
        }
    }
    
    private func stopPerformanceMonitoring() {
        performanceTimer?.invalidate()
        performanceTimer = nil
        frameCount = 0
    }
    
    private func logPerformanceMetrics() {
        let fps = frameCount
        frameCount = 0
        
        print("Performance: \(fps) FPS")
        
        // メモリ使用量の監視
        let memoryUsage = getMemoryUsage()
        print("Memory usage: \(memoryUsage) MB")
        
        // 必要に応じて品質調整
        if fps < 15 {
            // フレームレートが低い場合は品質を下げる
            setLowQualityMode()
        }
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        return 0.0
    }
    
    // MARK: - Bridge Callbacks
    
    private func setupBridgeCallbacks() {
        bridge.setOnScreenUpdate { [weak self] image in
            guard let self = self else { return }
            self.delegate?.connectionManager(self, didUpdateScreen: image)
            self.frameCount += 1
        }
        
        bridge.setOnConnectionStateChanged { [weak self] connected in
            guard let self = self else { return }
            self.isConnected = connected
            self.isConnecting = false
            
            if connected {
                self.startPerformanceMonitoring()
            } else {
                self.stopPerformanceMonitoring()
            }
            
            self.delegate?.connectionManager(self, didChangeState: connected)
        }
        
        bridge.setOnError { [weak self] errorMessage in
            guard let self = self else { return }
            let error = NSError(
                domain: "RDPConnectionManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
            self.delegate?.connectionManager(self, didEncounterError: error)
        }
    }
}
