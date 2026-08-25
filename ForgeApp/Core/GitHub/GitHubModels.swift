import Foundation

struct GitHubRepository: Codable, Identifiable, Hashable {
    let id: Int
    let fullName: String
    let name: String
    let defaultBranch: String
    let isPrivate: Bool

    var owner: String {
        fullName.split(separator: "/").first.map(String.init) ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case fullName = "full_name"
        case defaultBranch = "default_branch"
        case isPrivate = "private"
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

struct GitHubDeviceCodeResponse: Decodable {
    let deviceCode: String
    let userCode: String
    let verificationURI: URL
    let verificationURIComplete: URL?
    let expiresIn: Int
    let interval: Int?

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationURI = "verification_uri"
        case verificationURIComplete = "verification_uri_complete"
        case expiresIn = "expires_in"
        case interval
    }
}

struct GitHubOAuthTokenResponse: Decodable {
    let accessToken: String?
    let tokenType: String?
    let scope: String?
    let error: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope, error
        case errorDescription = "error_description"
    }
}

struct GitHubUser: Decodable, Identifiable, Equatable {
    let id: Int
    let login: String
    let name: String?
    let avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, login, name
        case avatarURL = "avatar_url"
    }
}

struct GitHubRepositoriesResponse: Decodable {
    let repositories: [GitHubRepository]
}
