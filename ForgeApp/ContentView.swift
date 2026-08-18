import SwiftUI
import Combine
import Security
import UniformTypeIdentifiers
import Compression
import UIKit

// MARK: - GitHub Models

struct GitHubWorkflowRun: Decodable {
    let id: Int
    let status: String
    let conclusion: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, status, conclusion
        case createdAt = "created_at"
    }
}

struct GitHubWorkflowRunsResponse: Decodable {
    let workflowRuns: [GitHubWorkflowRun]

    enum CodingKeys: String, CodingKey {
        case workflowRuns = "workflow_runs"
    }
}

struct GitHubArtifact: Decodable, Identifiable {
    let id: Int
    let name: String
    let sizeInBytes: Int
    let archiveDownloadURL: String
    let expired: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, expired
        case sizeInBytes = "size_in_bytes"
        case archiveDownloadURL = "archive_download_url"
    }
}

struct GitHubArtifactsResponse: Decodable {
    let artifacts: [GitHubArtifact]
}

// MARK: - Secure Token Storage

final class KeychainStore {
    static let shared = KeychainStore()
    private let service = "com.iraay.iForgeBuild.github"
    private let account = "github-token"

    func save(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        SecItemAdd(item as CFDictionary, nil)
    }

    func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - GitHub API

@MainActor
final class GitHubAPI: ObservableObject {
    static let shared = GitHubAPI()

    @Published private(set) var activeRun: GitHubWorkflowRun?
    @Published private(set) var isBuilding = false
    @Published var errorMessage: String?

    private let owner = "iRaay"
    private let engineRepository = "iForge"
    private let workflow = "build.yml"
    private let tokenStore = KeychainStore.shared

    var hasToken: Bool { tokenStore.load()?.isEmpty == false }

    func saveToken(_ token: String) {
        tokenStore.save(token.trimmingCharacters(in: .whitespacesAndNewlines))
        objectWillChange.send()
    }

    func disconnect() {
        tokenStore.delete()
        objectWillChange.send()
    }

    func startBuild(repository: String, branch: String) async {
        guard let token = tokenStore.load(), !token.isEmpty else {
            errorMessage = "Add a GitHub token in Settings first."
            return
        }

        let start = Date()
        isBuilding = true
        errorMessage = nil
        activeRun = nil

        do {
            let dispatchURL = URL(string: "https://api.github.com/repos/\(owner)/\(engineRepository)/actions/workflows/\(workflow)/dispatches")!
            var request = makeRequest(url: dispatchURL, token: token, method: "POST")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "ref": "main",
                "inputs": ["repository": repository, "branch": branch]
            ])
            _ = try await URLSession.shared.data(for: request)

            // GitHub returns 204 for dispatch. Find the newly-created run, then poll it.
            var run: GitHubWorkflowRun?
            for _ in 0..<30 {
                try await Task.sleep(for: .seconds(2))
                let runs = try await fetchRuns(token: token)
                run = runs.first(where: { ISO8601DateFormatter().date(from: $0.createdAt) ?? .distantPast >= start })
                if run != nil { break }
            }

            guard let initialRun = run else {
                throw APIError.message("Workflow was dispatched, but its run could not be found.")
            }

            activeRun = initialRun
            for _ in 0..<120 {
                let current = try await fetchRun(id: initialRun.id, token: token)
                activeRun = current
                if current.status == "completed" {
                    isBuilding = false
                    if current.conclusion != "success" {
                        throw APIError.message("Build failed. Open GitHub Actions for the build log.")
                    }
                    return
                }
                try await Task.sleep(for: .seconds(5))
            }

            throw APIError.message("Build is still running. You can refresh from Builds later.")
        } catch {
            isBuilding = false
            errorMessage = error.localizedDescription
        }
    }

    func fetchSuccessfulArtifacts(runID: Int) async throws -> [GitHubArtifact] {
        guard let token = tokenStore.load(), !token.isEmpty else { throw APIError.message("GitHub token missing.") }
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(engineRepository)/actions/runs/\(runID)/artifacts")!
        var request = makeRequest(url: url, token: token)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GitHubArtifactsResponse.self, from: data)
        return response.artifacts.filter { !$0.expired && $0.name.lowercased().hasSuffix(".ipa") }
    }

    func downloadArtifact(_ artifact: GitHubArtifact) async throws -> URL {
        guard let token = tokenStore.load(), !token.isEmpty else { throw APIError.message("GitHub token missing.") }
        guard let url = URL(string: artifact.archiveDownloadURL) else { throw APIError.message("Invalid artifact URL.") }
        let request = makeRequest(url: url, token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw APIError.message("GitHub rejected the artifact download.")
        }
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("artifact-\(artifact.id).zip")
        try data.write(to: zipURL, options: .atomic)
        return try unzipSingleFile(zipURL: zipURL, suggestedName: artifact.name)
    }

    private func fetchRuns(token: String) async throws -> [GitHubWorkflowRun] {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(engineRepository)/actions/workflows/\(workflow)/runs?event=workflow_dispatch&per_page=10")!
        var request = makeRequest(url: url, token: token)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(GitHubWorkflowRunsResponse.self, from: data).workflowRuns
    }

    private func fetchRun(id: Int, token: String) async throws -> GitHubWorkflowRun {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(engineRepository)/actions/runs/\(id)")!
        let request = makeRequest(url: url, token: token)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(GitHubWorkflowRun.self, from: data)
    }

    private func makeRequest(url: URL, token: String, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        return request
    }

    private enum APIError: LocalizedError {
        case message(String)
        var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
    }

    // Minimal ZIP reader for the single IPA file produced by upload-artifact.
    private func unzipSingleFile(zipURL: URL, suggestedName: String) throws -> URL {
        let data = try Data(contentsOf: zipURL)
        guard data.count > 30 else { throw APIError.message("Downloaded artifact is invalid.") }
        let signature: UInt32 = 0x04034b50
        guard data.withUnsafeBytes({ $0.load(as: UInt32.self) }) == signature else {
            throw APIError.message("Artifact is not a valid ZIP archive.")
        }
        let method = UInt16(data[8]) | UInt16(data[9]) << 8
        let compressedSize = UInt32(data[18]) | UInt32(data[19]) << 8 | UInt32(data[20]) << 16 | UInt32(data[21]) << 24
        let uncompressedSize = UInt32(data[22]) | UInt32(data[23]) << 8 | UInt32(data[24]) << 16 | UInt32(data[25]) << 24
        let nameLength = Int(UInt16(data[26]) | UInt16(data[27]) << 8)
        let extraLength = Int(UInt16(data[28]) | UInt16(data[29]) << 8)
        let payloadStart = 30 + nameLength + extraLength
        let payloadEnd = payloadStart + Int(compressedSize)
        guard payloadEnd <= data.count else { throw APIError.message("Artifact payload is incomplete.") }
        let compressed = data.subdata(in: payloadStart..<payloadEnd)
        let outputSize = Int(uncompressedSize)
        var output = Data(count: outputSize)

        if method == 0 {
            output = compressed
        } else if method == 8 {
            // ZIP stores raw DEFLATE. Wrap it in a zlib stream for Apple's Compression framework.
            var zlib = Data([0x78, 0x9C])
            zlib.append(compressed)
            var adler = Adler32.initial
            adler.update(output)
            let checksum = adler.value.bigEndian
            withUnsafeBytes(of: checksum) { zlib.append(contentsOf: $0) }
            let decodedSize = zlib.withUnsafeBytes { src in
                output.withUnsafeMutableBytes { dst in
                    compression_decode_buffer(dst.bindMemory(to: UInt8.self).baseAddress!, outputSize,
                                               src.bindMemory(to: UInt8.self).baseAddress!, zlib.count,
                                               nil, COMPRESSION_ZLIB)
                }
            }
            guard decodedSize == outputSize else { throw APIError.message("Could not decompress the IPA artifact.") }
        } else {
            throw APIError.message("Unsupported ZIP compression method.")
        }

        let fileName = suggestedName.hasSuffix(".ipa") ? suggestedName : "\(suggestedName).ipa"
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try output.write(to: destination, options: .atomic)
        return destination
    }
}

private struct Adler32 {
    private(set) var a: UInt32 = 1
    private(set) var b: UInt32 = 0
    static let initial = Adler32()
    mutating func update(_ data: Data) {
        for byte in data {
            a = (a + UInt32(byte)) % 65521
            b = (b + a) % 65521
        }
    }
    var value: UInt32 { (b << 16) | a }
}

// MARK: - App UI

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
        BuildItem(appName: "YouTube", repository: "iRaay/YouTube", build: 30, status: .success)
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
        .sheet(isPresented: $showingNewBuild) { NewBuildView() }
    }

    private var header: some View {
        HStack {
            Text("iForge").font(.largeTitle.bold())
            Spacer()
            Image(systemName: "gearshape").font(.title3)
        }
    }

    private var newBuildCard: some View {
        Button { showingNewBuild = true } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Build").font(.title2.bold())
                        Text("Build any iOS app from GitHub in a few taps.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "hammer.fill").font(.system(size: 42)).opacity(0.8)
                }
                Label("Start New Build", systemImage: "plus")
                    .font(.headline).padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.white, in: Capsule()).foregroundStyle(.purple)
            }
            .padding(20).foregroundStyle(.white)
            .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    private var recentBuilds: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Builds").font(.title3.bold())
                Spacer()
                Button("See All") { selectedTab = 1 }.font(.subheadline.weight(.semibold))
            }
            ForEach(builds) { build in BuildRow(build: build) }
        }
    }
}

struct BuildRow: View {
    let build: BuildItem
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.15)).frame(width: 48, height: 48)
                .overlay(Text(String(build.appName.prefix(1))).font(.title3.bold()))
            VStack(alignment: .leading, spacing: 4) {
                Text(build.appName).font(.headline)
                Text("Build \(build.build) · \(build.repository)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(build.status.title).font(.caption.bold()).padding(.horizontal, 9).padding(.vertical, 5)
                .background(build.status == .success ? .green.opacity(0.15) : .red.opacity(0.15), in: Capsule())
                .foregroundStyle(build.status == .success ? .green : .red)
        }
        .padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct NewBuildView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var api = GitHubAPI.shared
    @State private var repository = "iRaay/Navi"
    @State private var branch = "main"

    var body: some View {
        NavigationStack {
            Form {
                Section("GitHub Repository") { TextField("owner/repository", text: $repository).textInputAutocapitalization(.never) }
                Section("Branch") { TextField("main", text: $branch).textInputAutocapitalization(.never) }
                Section("Build") {
                    LabeledContent("Configuration", value: "Release")
                    LabeledContent("Engine", value: "iForge")
                }
                if api.isBuilding {
                    Section("Build Status") {
                        HStack { ProgressView(); Text("Building…") }
                        if let run = api.activeRun { Text("Run #\(run.id)").font(.caption).foregroundStyle(.secondary) }
                    }
                }
                if let error = api.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
                Section {
                    Button {
                        Task { await api.startBuild(repository: repository.trimmingCharacters(in: .whitespacesAndNewlines), branch: branch.trimmingCharacters(in: .whitespacesAndNewlines)) }
                    } label: {
                        Label("Start Build", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                    .disabled(api.isBuilding || !api.hasToken)
                }
                if !api.hasToken {
                    Section { Text("Add your GitHub token in Settings to start builds.").font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("New Build")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
        }
    }
}
