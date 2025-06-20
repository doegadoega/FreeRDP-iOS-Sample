import Foundation

struct RDPConnection: Codable {
    var id: String
    var name: String
    var host: String
    var port: Int
    var username: String
    var password: String?
    var domain: String?
    var lastConnected: Date?
    
    init(id: String = UUID().uuidString, name: String, host: String, port: Int = 3389, username: String, password: String? = nil, domain: String? = nil) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.domain = domain
    }
} 
