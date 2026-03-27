import Foundation
import NetworkExtension
import Combine

enum ConnectionState: String {
    case connected
    case connecting
    case disconnected
    case disconnecting
    case invalid
    case reasserting

    init(status: NEVPNStatus) {
        switch status {
        case .connected:
            self = .connected
        case .connecting:
            self = .connecting
        case .disconnected:
            self = .disconnected
        case .disconnecting:
            self = .disconnecting
        case .invalid:
            self = .invalid
        case .reasserting:
            self = .reasserting
        @unknown default:
            self = .invalid
        }
    }
}

final class VPNManager: ObservableObject {
    static let shared = VPNManager()

    private let manager = NEVPNManager.shared()

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var currentServer: VPNServer?

    @Published var autoConnect: Bool = false
    @Published var killSwitch: Bool = false

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStatusChange),
            name: NSNotification.Name.NEVPNStatusDidChange,
            object: nil
        )

        Task {
            await loadPreferences()
        }
    }

    func loadPreferences() async {
        do {
            try await manager.loadFromPreferences()
            connectionState = ConnectionState(status: manager.connection.status)
        } catch {
            print("Failed to load preferences: \(error)")
        }
    }

    func configure(server: VPNServer) async throws {
        currentServer = server

        try await manager.loadFromPreferences()

        let protocolConfig = NEVPNProtocolIKEv2()
        protocolConfig.serverAddress = server.ip
        protocolConfig.username = server.username

        if let password = server.password {
            let accountKey = "vpn.\(server.id.uuidString).password"
            _ = KeychainHelper.standard.save(password: password, account: accountKey)

            if let ref = KeychainHelper.standard.persistentReference(for: accountKey) {
                protocolConfig.passwordReference = ref
            }
        }

        protocolConfig.remoteIdentifier = server.ip
        protocolConfig.localIdentifier = nil
        protocolConfig.useExtendedAuthentication = true
        protocolConfig.disconnectOnSleep = false

        protocolConfig.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
        protocolConfig.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA256
        protocolConfig.ikeSecurityAssociationParameters.diffieHellmanGroup = .group20
        protocolConfig.ikeSecurityAssociationParameters.lifetimeMinutes = 1440

        protocolConfig.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
        protocolConfig.childSecurityAssociationParameters.integrityAlgorithm = .SHA256
        protocolConfig.childSecurityAssociationParameters.diffieHellmanGroup = .group20
        protocolConfig.childSecurityAssociationParameters.lifetimeMinutes = 1440

        manager.protocolConfiguration = protocolConfig
        manager.localizedDescription = "VPNApp"
        manager.isEnabled = true
        manager.isOnDemandEnabled = autoConnect

        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
    }

    func connect() async throws {
        guard manager.connection.status == .disconnected || manager.connection.status == .invalid else {
            return
        }

        try manager.connection.startVPNTunnel()
    }

    func disconnect() {
        manager.connection.stopVPNTunnel()
    }

    func toggle() async {
        switch manager.connection.status {
        case .connected:
            disconnect()

        case .disconnected, .invalid:
            do {
                if let server = currentServer {
                    if manager.protocolConfiguration == nil {
                        try await configure(server: server)
                    }
                    try await connect()
                }
            } catch {
                print("Error starting VPN: \(error)")
            }

        default:
            break
        }
    }

    @objc
    private func handleStatusChange() {
        let status = manager.connection.status
        connectionState = ConnectionState(status: status)

        if killSwitch && (status == .disconnected || status == .invalid) {
            print("VPN disconnected while kill switch is enabled.")
        }
    }
}
