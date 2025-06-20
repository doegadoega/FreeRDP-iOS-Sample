//
//  RDPConnectionError.swift
//  MyRDPApp
//
//  Created by Hiroshi Egami on 2025/06/18.
//


/// RDPにおけるConnectionError を実装
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
