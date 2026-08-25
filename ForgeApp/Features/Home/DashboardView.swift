import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("iForge").font(.largeTitle.bold())
                        Text("Build iOS apps from your repositories.")
                            .foregroundStyle(.secondary)
                    }

                    Button { selectedTab = 1 } label: {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("New Build", systemImage: "plus.circle.fill")
                                .font(.title2.bold())
                            Text("Choose a repository, configure a build, and receive a ready-to-sign IPA.")
                                .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                            Label("Select a project", systemImage: "folder")
                                .font(.headline).padding(.horizontal, 14).padding(.vertical, 9)
                                .background(.white, in: Capsule()).foregroundStyle(.purple)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(20)
                        .foregroundStyle(.white)
                        .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Builds").font(.title3.bold())
                        ContentUnavailableView("No Builds Yet", systemImage: "hammer",
                            description: Text("Connect GitHub, select a project, and start your first build."))
                            .frame(maxWidth: .infinity).padding(.vertical, 18)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}
