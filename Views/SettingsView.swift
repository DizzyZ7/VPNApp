import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: VPNViewModel

    var body: some View {
        Form {
            Section("Connection") {
                Toggle("Auto Connect on Launch", isOn: $viewModel.vpnManager.autoConnect)
                Toggle("Kill Switch", isOn: $viewModel.vpnManager.killSwitch)
            }

            Section("About") {
                Text("Version 1.0")
                Text("Build 1")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
        .environmentObject(VPNViewModel())
}
