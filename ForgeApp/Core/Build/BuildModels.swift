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

struct BuildRecord: Identifiable, Hashable {
    let id: Int
    let repository: GitHubRepository
    let branch: String
    let state: BuildState
    let createdAt: Date
    let ipaName: String?
}
