import SwiftUI

struct BuildItem: Identifiable {
    let id = UUID()
    let appName: String
    let repository: String
    let build: Int
    let status: BuildStatus
}

enum BuildStatus {
    case success, failed

    var title: String { self == .success ? "Success" : "Failed" }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingNewBuild = false

    private let builds = [
        BuildItem(appName: "Navi", repository: "iRaay/Navi", build: 42, status: .success),
        BuildItem(appName: "ChatGPT", repository: "iRaay/ChatGPT", build: 128, status: .success),
        BuildItem(appName: "YouTube", repository: "iRaay/YouTube", build: 30, status: .success),
        BuildItem(appName: "Instagram", repository: "iRaay/Instagram", build: 27, status: .failed)
    ]

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        newBuildCard
                        recentBuilds
                    }
                    .padding()
                }
                .navigationBarHidden(true)
            }
            .tabItem { Label("Builds", systemImage: "hammer.fill") }
            .tag(0)

            IPAFilesView()
                .tabItem { Label("IPA Files", systemImage: "archivebox.fill") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(.purple)
        .sheet(isPresented: $showingNewBuild) {
            NewBuildView()
        }
    }

    private var header: some View {
        HStack {
            Text("iForge")
                .font(.largeTitle.bold())
            Spacer()
            Image(systemName: "gearshape")
                .font(.title3)
        }
    }

    private var newBuildCard: some View {
        Button { showingNewBuild = true } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Build").font(.title2.bold())
                        Text("Build any iOS app from GitHub in a few taps.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 42))
                        .opacity(0.8)
                }
                Label("Start New Build", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white, in: Capsule())
                    .foregroundStyle(.purple)
            }
            .padding(20)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 22)
            )
        }
        .buttonStyle(.plain)
    }

    private var recentBuilds: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Builds").font(.title3.bold())
                Spacer()
                Button("See All") { selectedTab = 1 }
                    .font(.subheadline.weight(.semibold))
            }
            ForEach(builds) { build in
                BuildRow(build: build)
            }
        }
    }
}

struct BuildRow: View {
    let build: BuildItem

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(Text(String(build.appName.prefix(1))).font(.title3.bold()))
            VStack(alignment: .leading, spacing: 4) {
                Text(build.appName).font(.headline)
                Text("Build \(build.build) · \(build.repository)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(build.status.title)
                .font(.caption.bold())
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(build.status == .success ? .green.opacity(0.15) : .red.opacity(0.15), in: Capsule())
                .foregroundStyle(build.status == .success ? .green : .red)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct NewBuildView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var repository = "iRaay/Navi"
    @State private var branch = "main"

    var body: some View {
        NavigationStack {
            Form {
                Section("GitHub Repository") {
                    TextField("owner/repository", text: $repository)
                }
                Section("Branch") {
                    TextField("main", text: $branch)
                }
                Section("Build") {
                    LabeledContent("Configuration", value: "Release")
                    LabeledContent("iOS", value: "17.4+")
                }
                Section {
                    Button {
                        dismiss()
                    } label: {
                        Label("Start Build", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("New Build")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
