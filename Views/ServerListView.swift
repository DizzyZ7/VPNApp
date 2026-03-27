import SwiftUI

struct ServerListView: View {
    @ObservedObject var viewModel: ServerListViewModel
    @Binding var selection: VPNServer?

    var body: some View {
        List(viewModel.servers) { server in
            HStack {
                VStack(alignment: .leading) {
                    Text(server.name)

                    if let ping = server.ping {
                        Text("Ping: \(ping) ms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if selection?.id == server.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selection = server
                Task {
                    try? await VPNManager.shared.configure(server: server)
                }
            }
        }
    }
}

#Preview {
    ServerListView(
        viewModel: ServerListViewModel(),
        selection: .constant(nil)
    )
}
