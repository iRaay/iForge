import SwiftUI

enum OnboardingGate {
    static let key = "hasCompletedOnboarding"
    static var isCompleted: Bool { UserDefaults.standard.bool(forKey: key) }
    static func markCompleted() { UserDefaults.standard.set(true, forKey: key) }
}

struct OnboardingView: View {
    @StateObject private var auth = GitHubAuth.shared
    @State private var showingSignIn = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Image("iForgeLogo")
                .resizable()
                .frame(width: 132, height: 132)
                .shadow(color: .purple.opacity(0.45), radius: 28, y: 10)

            VStack(spacing: 6) {
                Text("iForge")
                    .font(.system(size: 42, weight: .heavy))
                Text("Build once. Sign anywhere.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 18) {
                featureRow(icon: "hammer.fill",
                           title: "Build from GitHub",
                           detail: "Any repository, any branch — straight to IPA.")
                featureRow(icon: "waveform.path.ecg.rectangle.fill",
                           title: "Live Pipeline",
                           detail: "Watch every build step in real time.")
                featureRow(icon: "archivebox.fill",
                           title: "IPA Library",
                           detail: "Download and share with Feather.")
            }
            .padding(.horizontal, 26)
            .padding(.top, 34)

            Spacer()

            if auth.user != nil {
                Button(action: OnboardingGate.markCompleted) {
                    Label("Get Started", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [.purple, .blue],
                                                   startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 26)
            } else {
                Button { showingSignIn = true } label: {
                    Label("Continue with GitHub", systemImage: "person.badge.key.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.purple, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 26)

                Button("Skip for Now") { OnboardingGate.markCompleted() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
            }
            Spacer(minLength: 30)
        }
        .sheet(isPresented: $showingSignIn) { GitHubSignInView() }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
