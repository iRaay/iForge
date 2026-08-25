import SwiftUI
import UIKit

struct GitHubSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = GitHubAuth.shared
    @State private var deviceCode: GitHubDeviceCodeResponse?
    @State private var isPresentingCode = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "hammer.fill")
                    .font(.system(size: 56)).foregroundStyle(.purple)
                Text("Connect GitHub").font(.title.bold())
                Text("iForge uses GitHub's secure device authorization. Your access token is stored only in your iOS Keychain.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                    .padding(.horizontal)

                if GitHubAppConfig.oauthClientID == nil {
                    ContentUnavailableView("OAuth Setup Required", systemImage: "key.slash",
                        description: Text("Add the GitHub OAuth App Client ID to GITHUB_OAUTH_CLIENT_ID in Info.plist, then rebuild iForge."))
                } else if let device = deviceCode {
                    VStack(spacing: 12) {
                        Text("Enter this code on GitHub").font(.headline)
                        Text(device.userCode).font(.system(.title, design: .monospaced).bold())
                            .textSelection(.enabled).padding().background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        Button("Open GitHub", systemImage: "arrow.up.right") {
                            UIApplication.shared.open(device.verificationURIComplete ?? device.verificationURI)
                            isPresentingCode = true
                            Task { await finish(device) }
                        }
                        .buttonStyle(.borderedProminent)
                        if auth.isLoading || isPresentingCode { ProgressView("Waiting for authorization…") }
                    }
                } else {
                    Button("Continue with GitHub", systemImage: "person.badge.key") {
                        Task { await begin() }
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .disabled(auth.isLoading)
                    if auth.isLoading { ProgressView() }
                }

                if let error = auth.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("GitHub")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
        }
    }

    private func begin() async {
        do { deviceCode = try await auth.beginDeviceAuthorization() }
        catch { auth.errorMessage = error.localizedDescription }
    }

    private func finish(_ device: GitHubDeviceCodeResponse) async {
        do {
            try await auth.completeDeviceAuthorization(device)
            dismiss()
        } catch { auth.errorMessage = error.localizedDescription }
    }
}
