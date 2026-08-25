import SwiftUI

struct SettingsView: View {
    @StateObject private var auth = GitHubAuth.shared
    @State private var showingSignIn = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let user = auth.user {
                        LabeledContent("GitHub", value: "@\(user.login)")
                        Button("Disconnect", role: .destructive) { auth.disconnect() }
                    } else {
                        Button("Connect GitHub", systemImage: "person.badge.key") { showingSignIn = true }
                        Text("Connect securely to view repositories and run iForge in your selected project.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
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
            .sheet(isPresented: $showingSignIn) { GitHubSignInView() }
            .task { await auth.restoreSession() }
        }
    }
}
