import Foundation

enum VPNProtocolType: String, Codable, CaseIterable {
    case ikev2
    case wireguard
    case openvpn
}

struct VPNServer: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let ip: String
    let protocolType: VPNProtocolType
    let username: String
    let password: String?
    let ping: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ip
        case username
        case password
        case ping
        case protocolType = "protocol"
    }

    init(
        id: UUID = UUID(),
        name: String,
        ip: String,
        protocolType: VPNProtocolType,
        username: String,
        password: String? = nil,
        ping: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.ip = ip
        self.protocolType = protocolType
        self.username = username
        self.password = password
        self.ping = ping
    }
}
