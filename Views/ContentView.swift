import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: VPNViewModel
    @State private var showingServerSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Text(viewModel.displayStatus)
                    .font(.title2)
                    .foregroundColor(viewModel.status == .connected ? .green : .primary)

                Button {
                    Task {
                        await viewModel.toggleConnection()
                    }
                } label: {
                    Text(viewModel.status == .connected ? "Disconnect" : "Connect")
                        .font(.headline)
                        .frame(width: 180, height: 180)
                        .background(viewModel.status == .connected ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .disabled(viewModel.selectedServer == nil)

                VStack(spacing: 8) {
                    Text("Session Duration: \(viewModel.sessionDuration)")
                        .font(.subheadline)

                    Text("Server: \(viewModel.selectedServer?.name ?? "None")")
                        .font(.subheadline)
                }

                Spacer()

                HStack {
                    Button("Choose Server") {
                        showingServerSheet.toggle()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .sheet(isPresented: $showingServerSheet) {
                        NavigationView {
                            ServerListView(
                                viewModel: viewModel.serverListViewModel,
                                selection: $viewModel.selectedServer
                            )
                            .navigationTitle("Servers")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Done") {
                                        showingServerSheet = false
                                    }
                                }
                            }
                        }
                    }

                    Spacer()

                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("VPN App")
        }
        .onAppear {
            viewModel.serverListViewModel.fetchServers()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(VPNViewModel())
}
