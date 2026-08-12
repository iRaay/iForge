import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct IPAItem: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
    let size: String
    let build: Int
    let artifact: GitHubArtifact?
}

struct IPAFilesView: View {
    @StateObject private var api = GitHubAPI.shared
    @State private var query = ""
    @State private var files: [IPAItem] = []
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            List {
                if files.isEmpty && !isRefreshing {
                    ContentUnavailableView("No IPA Files", systemImage: "archivebox", description: Text("Successful builds will appear here automatically."))
                }
                ForEach(filteredFiles) { file in
                    NavigationLink {
                        IPADetailView(file: file)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "doc.zipper")
                                .font(.title2)
                                .frame(width: 46, height: 46)
                                .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.name).font(.headline)
                                Text(file.fileName).font(.subheadline).foregroundStyle(.secondary)
                                Text("Build \(file.build) · \(file.size)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.down.circle.fill").foregroundStyle(.purple)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("IPA Files")
            .searchable(text: $query, prompt: "Search IPA files")
            .refreshable { await refresh() }
            .task { await refresh() }
            .overlay { if isRefreshing { ProgressView() } }
        }
    }

    private var filteredFiles: [IPAItem] {
        guard !query.isEmpty else { return files }
        return files.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.fileName.localizedCaseInsensitiveContains(query)
        }
    }

    private func refresh() async {
        guard api.hasToken else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let runsURL = URL(string: "https://api.github.com/repos/iRaay/iForge/actions/workflows/build.yml/runs?status=success&per_page=20")!
            var request = URLRequest(url: runsURL)
            request.setValue("Bearer \(KeychainStore.shared.load() ?? "")", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(GitHubWorkflowRunsResponse.self, from: data)

            var result: [IPAItem] = []
            for run in response.workflowRuns.prefix(20) {
                let artifacts = try await api.fetchSuccessfulArtifacts(runID: run.id)
                for artifact in artifacts where artifact.name.lowercased().hasSuffix(".ipa") {
                    let base = artifact.name.replacingOccurrences(of: ".ipa", with: "", options: .caseInsensitive)
                    result.append(IPAItem(
                        name: base,
                        fileName: artifact.name,
                        size: ByteCountFormatter.string(fromByteCount: Int64(artifact.sizeInBytes), countStyle: .file),
                        build: run.id,
                        artifact: artifact
                    ))
                }
            }
            files = result
        } catch {
            api.errorMessage = error.localizedDescription
        }
    }
}

struct IPADetailView: View {
    let file: IPAItem
    @StateObject private var api = GitHubAPI.shared
    @State private var downloadedURL: URL?
    @State private var isDownloading = false
    @State private var showingShareSheet = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.zipper").font(.system(size: 76)).foregroundStyle(.purple)
            Text(file.fileName).font(.title2.bold())
            Text(file.size).foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("App Name", value: file.name)
                LabeledContent("Build", value: "\(file.build)")
                LabeledContent("Status", value: "Build Successful")
            }
            .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

            HStack {
                Button("Download IPA", systemImage: "arrow.down") { Task { await download() } }
                    .buttonStyle(.borderedProminent).disabled(isDownloading || file.artifact == nil)
                Button("Open in Feather", systemImage: "signature") {
                    if downloadedURL != nil { showingShareSheet = true } else { Task { await download(andShare: true) } }
                }
                .buttonStyle(.bordered).disabled(isDownloading || file.artifact == nil)
            }

            if isDownloading { ProgressView("Downloading…") }
            if let error { Text(error).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center) }
            Spacer()
        }
        .padding()
        .navigationTitle(file.fileName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let downloadedURL { ShareSheet(items: [downloadedURL]) }
        }
    }

    private func download(andShare: Bool = false) async {
        guard let artifact = file.artifact else { return }
        isDownloading = true
        error = nil
        defer { isDownloading = false }
        do {
            let url = try await api.downloadArtifact(artifact)
            downloadedURL = url
            if andShare { showingShareSheet = true }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView: View {
    @StateObject private var api = GitHubAPI.shared
    @State private var token = ""
    @State private var showingToken = false

    var body: some View {
        NavigationStack {
            Form {
                Section("GitHub") {
                    LabeledContent("Account", value: "iRaay")
                    SecureField("GitHub token", text: $token)
                    Button("Save GitHub Token") {
                        api.saveToken(token)
                        token = ""
                    }
                    .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if api.hasToken {
                        Label("GitHub connected", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        Button("Disconnect", role: .destructive) { api.disconnect() }
                    }
                    Text("Use a GitHub fine-grained token with Actions: Read and write on iRaay/iForge. Keep the token private; iForge stores it only in the iOS Keychain.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Build Defaults") {
                    LabeledContent("Configuration", value: "Release")
                    LabeledContent("Minimum iOS", value: "17.0+")
                }
                Section("Notifications") {
                    Toggle("Build Completed", isOn: .constant(true))
                    Toggle("Build Failed", isOn: .constant(true))
                }
                Section("About") {
                    LabeledContent("iForge", value: "1.0.0")
                    LabeledContent("Product", value: "iForge Build")
                    LabeledContent("Bundle ID", value: "com.iraay.iForgeBuild")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
