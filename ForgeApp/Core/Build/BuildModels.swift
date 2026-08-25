import Foundation

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
