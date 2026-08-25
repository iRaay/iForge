import Foundation
import UIKit

@MainActor
final class BuildService: ObservableObject {
    static let shared = BuildService()

    @Published private(set) var trackedBuilds: [TrackedBuild] = []
    @Published private(set) var runStates: [Int: GitHubWorkflowRun] = [:]
    @Published private(set) var jobDetails: [Int: [BuildJob]] = [:]

    private let defaults = UserDefaults.standard
    private static let storageKey = "iforge.trackedBuilds"
    private static let settingsPrefix = "iforge.buildSettings."

    private init() {
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([TrackedBuild].self, from: data) {
            trackedBuilds = decoded.sorted { $0.startedAt > $1.startedAt }
        }
    }

    // MARK: - Settings Memory

    func rememberedSettings(for repository: GitHubRepository) -> (branch: String, configuration: BuildConfiguration, clean: Bool, plugins: Bool)? {
        guard let data = defaults.data(forKey: Self.settingsPrefix + repository.fullName),
              let saved = try? JSONDecoder().decode(SavedSettings.self, from: data) else { return nil }
        return (saved.branch, saved.configuration, saved.cleanBuild, saved.allowPackagePlugins)
    }

    func remember(request: BuildRequest) {
        let saved = SavedSettings(branch: request.branch, configuration: request.configuration,
                                  cleanBuild: request.cleanBuild, allowPackagePlugins: request.allowPackagePlugins)
        if let data = try? JSONEncoder().encode(saved) {
            defaults.set(data, forKey: Self.settingsPrefix + request.repository.fullName)
        }
    }

    private struct SavedSettings: Codable {
        let branch: String
        let configuration: BuildConfiguration
        let cleanBuild: Bool
        let allowPackagePlugins: Bool
    }

    // MARK: - Start

    /// Installs (or updates) the iForge workflow in the repository, dispatches
    /// the build, and starts tracking the new run.
    func start(_ request: BuildRequest) async throws {
        guard GitHubAuth.shared.isConnected else { throw GitHubAuthError.notConnected }
        remember(request: request)

        let api = GitHubAPI.shared
        try await api.installWorkflow(repository: request.repository)

        // Give GitHub a moment to register the newly pushed workflow file.
        try await Task.sleep(for: .seconds(2))

        let startedAt = Date()
        try await api.dispatchBuild(repository: request.repository,
                                    branch: request.branch,
                                    configuration: request.configuration,
                                    cleanBuild: request.cleanBuild,
                                    allowPackagePlugins: request.allowPackagePlugins)

        let runId = try await locateNewRun(request: request, startedAt: startedAt)
        let tracked = TrackedBuild(repositoryFullName: request.repository.fullName,
                                   runId: runId, branch: request.branch,
                                   configuration: request.configuration.rawValue,
                                   startedAt: startedAt)
        trackedBuilds.insert(tracked, at: 0)
        persist()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func locateNewRun(request: BuildRequest, startedAt: Date) async throws -> Int {
        let api = GitHubAPI.shared
        for _ in 0..<30 {
            try await Task.sleep(for: .seconds(2))
            let urlString = "https://api.github.com/repos/\(request.repository.fullName)/actions/workflows/\(WorkflowTemplate.fileName)/runs?event=workflow_dispatch&per_page=5"
            guard let url = URL(string: urlString) else { throw GitHubAPIError.invalidResponse }
            let httpRequest = try GitHubAuth.shared.authorizedRequest(url: url)
            let (data, _) = try await URLSession.shared.data(for: httpRequest)
            let runs = (try? JSONDecoder().decode(GitHubWorkflowRunsResponse.self, from: data))?.workflowRuns ?? []
            let formatter = ISO8601DateFormatter()
            if let run = runs.first(where: { (formatter.date(from: $0.createdAt) ?? .distantPast) >= startedAt.addingTimeInterval(-5) }) {
                return run.id
            }
        }
        throw GitHubAPIError.invalidResponse
    }

    // MARK: - Refresh

    func refresh() async {
        let api = GitHubAPI.shared
        for build in trackedBuilds {
            guard let repo = repository(named: build.repositoryFullName) else { continue }
            guard let run = try? await api.fetchRun(id: build.runId, repository: repo) else { continue }
            runStates[build.runId] = run
            if run.status != "completed" || run.conclusion == "success" {
                jobDetails[build.runId] = (try? await api.fetchJobs(repository: repo, runId: build.runId)) ?? jobDetails[build.runId]
            }
        }
        objectWillChange.send()
    }

    /// Minimal repository handle for API calls on tracked builds.
    private func repository(named fullName: String) -> GitHubRepository? {
        guard let data = defaults.data(forKey: "iforge.repo." + fullName) else { return nil }
        return try? JSONDecoder().decode(GitHubRepository.self, from: data)
    }

    func cache(repository: GitHubRepository) {
        if let data = try? JSONEncoder().encode(repository) {
            defaults.set(data, forKey: "iforge.repo." + repository.fullName)
        }
    }

    func state(for build: TrackedBuild) -> BuildState {
        guard let run = runStates[build.runId] else { return .queued }
        if run.status != "completed" { return run.status == "queued" ? .queued : .running }
        return run.conclusion == "success" ? .success : .failed
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(trackedBuilds) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
