import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("GitHub", value: "Not connected")
                    Text("Secure GitHub sign-in will be added in the next milestone. iForge will never require a fixed account or repository.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Build Defaults") {
                    LabeledContent("Configuration", value: "Release")
                    LabeledContent("Minimum iOS", value: "17.0+")
                }

                Section("Storage") {
                    LabeledContent("IPA Files", value: "0")
                }

                Section("About") {
                    LabeledContent("iForge", value: "1.0.0")
                    Text("Build once. Sign anywhere.").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
