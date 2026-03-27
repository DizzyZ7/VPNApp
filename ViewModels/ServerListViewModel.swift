import Foundation

@MainActor
final class ServerListViewModel: ObservableObject {
    @Published var servers: [VPNServer] = []
    @Published var selectedServer: VPNServer?

    func fetchServers() {
        servers = APIClient.loadServersFromBundle()
    }
}
