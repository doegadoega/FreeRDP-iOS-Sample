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
  
  static let shared = RDPConnectionManager()
  private let connectionsKey = "savedRDPConnections"
    
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
  
  // MARK: - Properties
  
  weak var delegate: RDPConnectionManagerDelegate?
  
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
  
  // MARK: - Initialization
  
  init() {
    bridge = FreeRDPBridge()
    setupBridgeCallbacks()
    debugPrint("RDPConnectionManager initialized")
    startNetworkMonitoring()
  }
  
  deinit {
    stopNetworkMonitoring()
    performanceTimer?.invalidate()
    disconnect()
    debugPrint("RDPConnectionManager deinitialized")
  }
  
  // MARK: - Connection Management
  
  func connect(to hostname: String, port: Int, username: String, password: String, domain: String = "") {
    guard !isConnected && !isConnecting else {
      debugPrint("Already connected or connecting")
      return
    }
    
    self.hostname = hostname
    self.port = port
    self.username = username
    self.password = password
    self.domain = domain
    
    isConnecting = true
    
    debugPrint("Connecting to \(hostname):\(port) as \(username)")
    
    // バックグラウンドスレッドで接続処理を実行
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      
      let success = self.bridge.connect(
        toHost: hostname,
        port: Int32(port),
        username: username,
        password: password,
        domain: domain
      )
      
      DispatchQueue.main.async {
        if !success {
          self.isConnecting = false
          let error = NSError(
            domain: "RDPConnectionManager",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "接続の開始に失敗しました"]
          )
          self.delegate?.connectionManager(self, didEncounterError: error)
        }
      }
    }
  }
  
  func disconnect() {
    guard isConnected || isConnecting else { return }
    
    debugPrint("Disconnecting from RDP session")
    bridge.disconnect()
    
    isConnected = false
    isConnecting = false
    
    stopPerformanceMonitoring()
    delegate?.connectionManager(self, didChangeState: false)
  }
  
  // MARK: - Input Handling
  
  func sendMouseEvent(at point: CGPoint, isDown: Bool, button: Int) {
    guard isConnected else { return }
    bridge.sendMouseEvent(point, isDown: isDown, button: Int32(button))
  }
  
  func sendKeyEvent(_ keyCode: Int, isDown: Bool) {
    guard isConnected else { return }
    bridge.sendKeyEvent(Int32(keyCode), isDown: isDown)
  }
  
  func sendScrollEvent(at point: CGPoint, delta: CGFloat) {
    guard isConnected else { return }
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
//    bridge.enableDebugLogging(<#T##Bool#>)
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

// MARK: - Error Types

enum RDPConnectionError: Error, LocalizedError {
  case invalidParameters
  case connectionFailed
  case authenticationFailed
  case networkError
  case unknownError(String)
  
  var errorDescription: String? {
    switch self {
    case .invalidParameters:
      return "Invalid connection parameters"
    case .connectionFailed:
      return "Failed to connect to remote host"
    case .authenticationFailed:
      return "Authentication failed"
    case .networkError:
      return "Network error occurred"
    case .unknownError(let message):
      return message
    }
  }
}
