import Foundation

struct BuildRequest: Hashable {
    let repository: GitHubRepository
    var branch: String
    var configuration: BuildConfiguration
    var cleanBuild: Bool
    var allowPackagePlugins: Bool
}

enum BuildConfiguration: String, CaseIterable, Identifiable {
    case release = "Release"
    case debug = "Debug"
    var id: String { rawValue }
}

enum BuildState: String, CaseIterable {
    case queued, running, success, failed

    var title: String {
        switch self {
        case .queued: return "Queued"
        case .running: return "Building"
        case .success: return "Success"
        case .failed: return "Failed"
        }
    }
}

struct TrackedBuild: Codable, Identifiable, Hashable {
    let repositoryFullName: String
    let runId: Int
    let branch: String
    let configuration: String
    let startedAt: Date

    var id: Int { runId }
}

struct BuildStep: Identifiable, Hashable {
    let name: String
    let status: String
    let conclusion: String?

    var id: String { "\(name)-\(status)" }
    var isDone: Bool { status == "completed" }
    var didFail: Bool { conclusion == "failure" || conclusion == "cancelled" }
}

struct BuildJob: Identifiable, Hashable {
    let id: Int
    let name: String
    let status: String
    let conclusion: String?
    let steps: [BuildStep]
}
