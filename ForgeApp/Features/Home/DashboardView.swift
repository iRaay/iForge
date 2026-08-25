import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var auth = GitHubAuth.shared
    @StateObject private var service = BuildService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("iForge").font(.largeTitle.bold())
                        Text("Build iOS apps from your repositories.")
                            .foregroundStyle(.secondary)
                    }

                    if !auth.isConnected {
                        Button { selectedTab = 4 } label: {
                            Label("Connect GitHub to get started", systemImage: "person.badge.key")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.purple)
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
                        HStack {
                            Text("Recent Builds").font(.title3.bold())
                            Spacer()
                            if !service.trackedBuilds.isEmpty {
                                Button("See All") { selectedTab = 2 }
                                    .font(.subheadline.weight(.semibold))
                            }
                        }

                        if service.trackedBuilds.isEmpty {
                            ContentUnavailableView("No Builds Yet", systemImage: "hammer",
                                description: Text(auth.isConnected
                                    ? "Select a project and start your first build."
                                    : "Connect GitHub, select a project, and start your first build."))
                                .frame(maxWidth: .infinity).padding(.vertical, 18)
                        } else {
                            ForEach(Array(service.trackedBuilds.prefix(3))) { build in
                                NavigationLink { BuildDetailView(build: build) } label: {
                                    BuildRow(build: build)
                                        .padding(12)
                                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .refreshable { await service.refresh() }
            .task { await service.refresh() }
        }
    }
}
