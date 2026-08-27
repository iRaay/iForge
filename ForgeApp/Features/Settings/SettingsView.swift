import SwiftUI

struct SettingsView: View {
    @StateObject private var auth = GitHubAuth.shared
    @AppStorage(NotificationManager.enabledKey) private var notificationsEnabled = true
    @AppStorage("appLanguage") private var appLanguage = "system"
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var showingSignIn = false
    @State private var ipaCount = 0

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

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

                Section("Appearance") {
                    Picker("Theme", selection: $appTheme) {
                        Label("System", systemImage: "circle.lefthalf.filled").tag("system")
                        Label("Light", systemImage: "sun.max.fill").tag("light")
                        Label("Dark", systemImage: "moon.fill").tag("dark")
                    }
                    Picker("Language", selection: $appLanguage) {
                        Text("System").tag("system")
                        Text("English").tag("en")
                        Text("العربية").tag("ar")
                    }
                }

                Section("Build Defaults") {
                    LabeledContent("Xcode Build Type", value: "Release")
                    LabeledContent("Minimum iOS", value: "17.0+")
                }

                Section("Notifications") {
                    Toggle("Build Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled { NotificationManager.shared.requestAuthorization() }
                        }
                    Text("Get notified when a build finishes.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Storage") {
                    LabeledContent("IPA Files", value: "\(ipaCount)")
                }

                Section("About") {
                    LabeledContent("iForge", value: appVersion)
                    Text("Build once. Sign anywhere.").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSignIn) { GitHubSignInView() }
            .task {
                await auth.restoreSession()
                ipaCount = IPAFilesView.savedFiles().count
            }
        }
    }
}
