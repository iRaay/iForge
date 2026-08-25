import SwiftUI

struct IPADownloadView: View {
    let build: TrackedBuild
    @State private var artifacts: [GitHubArtifact] = []
    @State private var isLoading = true
    @State private var downloadingID: Int?
    @State private var message: String?
    @State private var savedFile: IPAFilesView.SavedIPA?
    @State private var showingShare = false

    var body: some View {
        List {
            if isLoading {
                Section { HStack { ProgressView(); Text("Loading artifacts…") } }
            } else if artifacts.isEmpty {
                Section {
                    ContentUnavailableView("No IPA Artifacts", systemImage: "archivebox",
                        description: Text("Artifacts expire after 14 days."))
                }
            } else {
                ForEach(artifacts) { artifact in
                    Button {
                        Task { await download(artifact) }
                    } label: {
                        HStack {
                            Image(systemName: "doc.zipper").foregroundStyle(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(artifact.name).font(.headline)
                                Text(ByteCountFormatter.string(fromByteCount: Int64(artifact.sizeInBytes), countStyle: .file))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if downloadingID == artifact.id {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.down.circle.fill").foregroundStyle(.purple)
                            }
                        }
                    }
                    .disabled(downloadingID != nil)
                }
            }

            if let message { Section { Text(message).foregroundStyle(.secondary) } }
            if let savedFile {
                Section {
                    Button("Share \(savedFile.name)", systemImage: "square.and.arrow.up") { showingShare = true }
                }
            }
        }
        .navigationTitle("IPA Files")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showingShare) {
            if let savedFile { ShareSheet(items: [savedFile.url]) }
        }
    }

    private func load() async {
        let repo = GitHubRepository(id: 0, fullName: build.repositoryFullName,
                                    name: build.repositoryFullName.split(separator: "/").last.map(String.init) ?? "",
                                    defaultBranch: build.branch, isPrivate: true)
        defer { isLoading = false }
        artifacts = (try? await GitHubAPI.shared.fetchIPAArtifacts(repository: repo, runId: build.runId)) ?? []
    }

    private func download(_ artifact: GitHubArtifact) async {
        downloadingID = artifact.id
        message = nil
        defer { downloadingID = nil }

        let repo = GitHubRepository(id: 0, fullName: build.repositoryFullName,
                                    name: build.repositoryFullName.split(separator: "/").last.map(String.init) ?? "",
                                    defaultBranch: build.branch, isPrivate: true)
        do {
            let zipData = try await GitHubAPI.shared.downloadArtifact(artifact, repository: repo)
            let ipaData = try ArtifactExtractor.extractSingleFile(from: zipData)
            let dir = IPAFilesView.documentsDirectory
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let destination = dir.appendingPathComponent(artifact.name)
            try ipaData.write(to: destination, options: .atomic)
            savedFile = IPAFilesView.SavedIPA(url: destination)
            message = "Saved to IPA Files."
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            message = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
