import Foundation

struct GitHubRepository: Identifiable, Hashable {
    let id: Int
    let fullName: String
    let name: String
    let defaultBranch: String
    let isPrivate: Bool

    var owner: String {
        fullName.split(separator: "/").first.map(String.init) ?? ""
    }
}

struct GitHubWorkflowRun: Decodable, Identifiable {
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
