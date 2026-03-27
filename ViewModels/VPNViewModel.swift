import Foundation
import Combine

@MainActor
final class VPNViewModel: ObservableObject {
    @Published var status: ConnectionState = .disconnected
    @Published var selectedServer: VPNServer?
    @Published var sessionStartDate: Date?

    let vpnManager = VPNManager.shared
    let serverListViewModel = ServerListViewModel()

    private var cancellables = Set<AnyCancellable>()

    init() {
        vpnManager.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.status = state
                if state == .connected && self?.sessionStartDate == nil {
                    self?.sessionStartDate = Date()
                }
                if state == .disconnected {
                    self?.sessionStartDate = nil
                }
            }
            .store(in: &cancellables)

        vpnManager.$currentServer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] server in
                self?.selectedServer = server
            }
            .store(in: &cancellables)
    }

    var displayStatus: String {
        switch status {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .disconnecting:
            return "Disconnecting..."
        case .invalid:
            return "Invalid"
        case .reasserting:
            return "Reasserting..."
        }
    }

    func toggleConnection() async {
        await vpnManager.toggle()
    }

    var sessionDuration: String {
        guard let start = sessionStartDate, status == .connected else { return "--" }

        let interval = Date().timeIntervalSince(start)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: interval) ?? "--"
    }
}
