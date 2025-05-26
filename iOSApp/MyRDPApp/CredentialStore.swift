//
//  CredentialStore.swift
//  MyRDPApp
//
//  Created on 2025/05/23.
//  Copyright © 2025 MyRDPApp. All rights reserved.
//

import Foundation
import Security

// 認証情報を表す構造体
struct RDPCredentials: Codable {
  let host: String
  let port: Int
  let username: String
  let password: String
  let domain: String?
  let createdAt: Date
  
  var displayName: String {
    if let domain = domain, !domain.isEmpty {
      return "\(domain)\\\(username)@\(host):\(port)"
    } else {
      return "\(username)@\(host):\(port)"
    }
  }
  
  init(host: String, port: Int, username: String, password: String, domain: String? = nil) {
    self.host = host
    self.port = port
    self.username = username
    self.password = password
    self.domain = domain
    self.createdAt = Date()
  }
}

// キーチェーンエラーを表すenum
enum KeychainError: Error, LocalizedError {
  case itemNotFound
  case duplicateItem
  case invalidData
  case unexpectedPasswordData
  case unhandledError(status: OSStatus)
  
  var errorDescription: String? {
    switch self {
    case .itemNotFound:
      return "認証情報が見つかりません"
    case .duplicateItem:
      return "認証情報が既に存在します"
    case .invalidData:
      return "無効なデータです"
    case .unexpectedPasswordData:
      return "パスワードデータが不正です"
    case .unhandledError(let status):
      return "キーチェーンエラー: \(status)"
    }
  }
}

// 認証情報の安全な保存と取得を管理するクラス
class CredentialStore {
  
  // MARK: - Singleton
  
  static let shared = CredentialStore()
  
  private init() {
    debugPrint("CredentialStore initialized")
  }
  
  // MARK: - Properties
  
  private let keychain = KeychainWrapper()
  private let credentialsKey = "com.myrdpapp.credentials"
  private let queue = DispatchQueue(label: "com.myrdpapp.credentialstore", qos: .userInitiated)
  
  // MARK: - Credential Management
  
  func saveCredentials(host: String, port: Int, username: String, password: String, domain: String? = nil) throws {
    let credential = RDPCredentials(host: host, port: port, username: username, password: password, domain: domain)
    
    // queue.syncを使って同期処理を行う代わりに、安全な更新方法を使用
    // 既存の認証情報を取得
    var credentials = try loadAllCredentials()
    
    // 同じホストとユーザー名の認証情報を更新または追加
    if let index = credentials.firstIndex(where: { $0.host == host && $0.username == username }) {
      credentials[index] = credential
    } else {
      credentials.append(credential)
    }
    
    // 保存
    try saveCredentialsToKeychain(credentials)
    
    debugPrint("Saved credentials for \(username)@\(host):\(port)")
  }
  
  func loadCredentials(for host: String, username: String) throws -> RDPCredentials? {
    // queueの二重同期を避けるため
    let credentials = try loadAllCredentials()
    return credentials.first { $0.host == host && $0.username == username }
  }
  
  func loadAllCredentials() throws -> [RDPCredentials] {
    // queueの二重同期を避けるために関数内でsyncを使用しない
    guard let data = try keychain.load(key: credentialsKey) else {
      return []
    }
    return try JSONDecoder().decode([RDPCredentials].self, from: data)
  }
  
  func deleteCredentials(host: String, username: String) throws {
    // 安全な方法で認証情報を削除
    var credentials = try loadAllCredentials()
    credentials.removeAll { $0.host == host && $0.username == username }
    try saveCredentialsToKeychain(credentials)
    
    debugPrint("Deleted credentials for \(username)@\(host)")
  }
  
  func clearAllCredentials() throws {
    // キーチェーンからすべての認証情報を削除
    try keychain.delete(key: credentialsKey)
    debugPrint("Cleared all credentials")
  }
  
  // MARK: - Debug Methods
  
#if DEBUG
#endif
  
  // MARK: - Private Methods
  
  private func saveCredentialsToKeychain(_ credentials: [RDPCredentials]) throws {
    let data = try JSONEncoder().encode(credentials)
    try keychain.save(key: credentialsKey, data: data)
  }
}

// MARK: - RDPCredential

struct RDPCredential: Codable {
  let host: String
  let port: Int
  let username: String
  let password: String
  let domain: String?
  let createdAt: Date
  
  var displayName: String {
    if let domain = domain, !domain.isEmpty {
      return "\(domain)\\\(username)@\(host):\(port)"
    } else {
      return "\(username)@\(host):\(port)"
    }
  }
  
  init(host: String, port: Int, username: String, password: String, domain: String? = nil) {
    self.host = host
    self.port = port
    self.username = username
    self.password = password
    self.domain = domain
    self.createdAt = Date()
  }
}

// MARK: - KeychainWrapper

class KeychainWrapper {
  private let queue = DispatchQueue(label: "com.myrdpapp.keychainwrapper", qos: .userInitiated)
  
  func save(key: String, data: Data) throws {
    // 実際の実装では、キーチェーンAPIを使用してデータを安全に保存
    // ここでは、UserDefaultsを使用した簡易的な実装
    UserDefaults.standard.set(data, forKey: key)
  }
  
  func load(key: String) throws -> Data? {
    // 実際の実装では、キーチェーンAPIを使用してデータを安全に読み込み
    // ここでは、UserDefaultsを使用した簡易的な実装
    return UserDefaults.standard.data(forKey: key)
  }
  
  func delete(key: String) throws {
    // 実際の実装では、キーチェーンAPIを使用してデータを安全に削除
    // ここでは、UserDefaultsを使用した簡易的な実装
    UserDefaults.standard.removeObject(forKey: key)
  }
}

// MARK: - Extensions

extension CredentialStore {
  
  /// 便利メソッド: 便利メソッド: パスワードのみ取得
  func getPassword(host: String, port: Int = 3389, username: String) throws -> String {
    let credentials = try loadCredentials(for: host, username: username)
    return credentials?.password ?? ""
  }
  
  /// 便利メソッド: 認証情報の更新
  func updateCredentials(_ credential: RDPCredential) throws {
    // 既存の認証情報を削除してから新しいものを保存
    try deleteCredentials(host: credential.host, username: credential.username)
    try saveCredentials(host: credential.host, port: credential.port, username: credential.username, password: credential.password, domain: credential.domain)
  }
}

// MARK: - Migration Support

extension CredentialStore {
  
  /// 古いバージョンからの認証情報移行
  func migrateFromOldVersion() {
    // 古いキーチェーンアイテムの形式から新しい形式への移行処理
    // 実装は必要に応じて追加
  }
  
  /// 認証情報のバックアップ作成
  func createBackup() throws -> Data {
    let allCredentials = try loadAllCredentials()
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    
    let backupData = try encoder.encode(allCredentials.map { credential in
      return [
        "host": credential.host,
        "port": String(credential.port),
        "username": credential.username,
        "domain": credential.domain ?? ""
        // パスワードはセキュリティ上バックアップに含めない
      ]
    })
    
    return backupData
  }
  
  /// バックアップからの復元（パスワードは手動入力が必要）
  func restoreFromBackup(_ data: Data) throws -> [RDPCredentials] {
    let backupItems = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
    
    var restoredCredentials: [RDPCredentials] = []
    
    for item in backupItems {
      if let host = item["host"] as? String,
         let port = item["port"] as? String,
         let username = item["username"] as? String {
        
        let domain = item["domain"] as? String
        let finalDomain = (domain?.isEmpty == true) ? nil : domain
        
        // パスワードは空文字列として復元（後で手動入力が必要）
        let credentials = RDPCredentials(
          host: host,
          port: Int(port) ?? 0,
          username: username,
          password: "",
          domain: finalDomain
        )
        
        restoredCredentials.append(credentials)
      }
    }
    
    return restoredCredentials
  }
}

// MARK: - Debug Support

#if DEBUG
extension CredentialStore {
  
  /// デバッグ用: 全ての認証情報を表示（パスワードは隠す）
  func debugPrintAllCredentials() {
    do {
      let credentials = try loadAllCredentials()
      print("=== Stored Credentials ===")
      for credential in credentials {
        print("Host: \(credential.host):\(credential.port)")
        print("Username: \(credential.username)")
        print("Domain: \(credential.domain ?? "None")")
        print("Password: [HIDDEN]")
        print("---")
      }
      print("Total: \(credentials.count) credentials")
    } catch {
      print("Failed to load credentials: \(error)")
    }
  }
  
  /// デバッグ用: テスト認証情報の作成
  func createTestCredentials() {
    let testCredentials = [
      RDPCredential(host: "test1.example.com", port: 3389, username: "testuser1", password: "testpass1", domain: "TESTDOMAIN"),
      RDPCredential(host: "test2.example.com", port: 3389, username: "testuser2", password: "testpass2", domain: nil),
      RDPCredential(host: "192.168.1.100", port: 3389, username: "admin", password: "adminpass", domain: nil)
    ]
    
    for credential in testCredentials {
      do {
        try saveCredentials(host: credential.host, port: credential.port, username: credential.username, password: credential.password, domain: credential.domain)
        print("Saved test credential: \(credential.displayName)")
      } catch {
        print("Failed to save test credential: \(error)")
      }
    }
  }
}
#endif
