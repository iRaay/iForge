import Foundation

@MainActor
final class GitHubAPI: ObservableObject {
    static let shared = GitHubAPI()

    // MARK: - Repositories

    func fetchAuthenticatedUserRepositories() async throws -> [GitHubRepository] {
        var all: [GitHubRepository] = []
        var page = 1

        while page <= 20 {
            var url = URLComponents(string: "https://api.github.com/user/repos")!
            url.queryItems = [
                URLQueryItem(name: "sort", value: "pushed"),
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "page", value: String(page))
            ]
            let request = try GitHubAuth.shared.authorizedRequest(url: url.url!)
            let (data, response) = try await URLSession.shared.data(for: request)
            try Self.validate(response)
            let batch = try JSONDecoder().decode([GitHubRepository].self, from: data)
            all.append(contentsOf: batch)
            if batch.count < 100 { break }
            page += 1
        }

        return all
    }

    // MARK: - Workflow Installation

    /// Returns the SHA of the existing workflow file, or nil when absent.
    func workflowSHA(repository: GitHubRepository) async throws -> String? {
        let urlString = "https://api.github.com/repos/\(repository.fullName)/contents/\(WorkflowTemplate.path)"
        guard let url = URL(string: urlString) else { throw GitHubAPIError.invalidResponse }
        let request = try GitHubAuth.shared.authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 404 { return nil }
        try Self.validate(response)
        struct ContentsResponse: Decodable { let sha: String }
        return try JSONDecoder().decode(ContentsResponse.self, from: data).sha
    }

    func installWorkflow(repository: GitHubRepository) async throws {
        let sha = try await workflowSHA(repository: repository)
        let urlString = "https://api.github.com/repos/\(repository.fullName)/contents/\(WorkflowTemplate.path)"
        guard let url = URL(string: urlString) else { throw GitHubAPIError.invalidResponse }
        var request = try GitHubAuth.shared.authorizedRequest(url: url, method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "message": sha == nil ? "Install iForge build workflow" : "Update iForge build workflow",
            "content": Data(WorkflowTemplate.yaml.utf8).base64EncodedString()
        ]
        if let sha { body["sha"] = sha }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
    }

    // MARK: - Dispatch and Tracking

    func dispatchBuild(repository: GitHubRepository, branch: String,
                       configuration: BuildConfiguration, cleanBuild: Bool,
                       allowPackagePlugins: Bool) async throws {
        let urlString = "https://api.github.com/repos/\(repository.fullName)/actions/workflows/\(WorkflowTemplate.fileName)/dispatches"
        guard let url = URL(string: urlString) else { throw GitHubAPIError.invalidResponse }
        var request = try GitHubAuth.shared.authorizedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ref": repository.defaultBranch,
            "inputs": [
                "branch": branch,
                "configuration": configuration.rawValue,
                "clean_build": cleanBuild,
                "allow_package_plugins": allowPackagePlugins
            ]
        ])
        let (_, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
    }

    func fetchRun(id: Int, repository: GitHubRepository) async throws -> GitHubWorkflowRun {
        let urlString = "https://api.github.com/repos/\(repository.fullName)/actions/runs/\(id)"
        guard let url = URL(string: urlString) else { throw GitHubAPIError.invalidResponse }
        let request = try GitHubAuth.shared.authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
        return try JSONDecoder().decode(GitHubWorkflowRun.self, from: data)
    }

    func fetchJobs(repository: GitHubRepository, runId: Int) async throws -> [BuildJob] {
        let urlString = "https://api.github.com/repos/\(repository.fullName)/actions/runs/\(runId)/jobs"
        guard let url = URL(string: urlString) else { throw GitHubAPIError.invalidResponse }
        let request = try GitHubAuth.shared.authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        struct JobsResponse: Decodable {
            struct JobDTO: Decodable {
                let id: Int
                let name: String
                let status: String
                let conclusion: String?
                let steps: [StepDTO]?
            }
            struct StepDTO: Decodable {
                let name: String
                let status: String
                let conclusion: String?
            }
            let jobs: [JobDTO]
        }
        let decoded = try JSONDecoder().decode(JobsResponse.self, from: data)
        return decoded.jobs.map { job in
            BuildJob(id: job.id, name: job.name, status: job.status,
                     conclusion: job.conclusion,
                     steps: (job.steps ?? []).map { BuildStep(name: $0.name, status: $0.status, conclusion: $0.conclusion) })
        }
    }

    // MARK: - Artifacts

    func fetchIPAArtifacts(repository: GitHubRepository, runId: Int) async throws -> [GitHubArtifact] {
        let urlString = "https://api.github.com/repos/\(repository.fullName)/actions/runs/\(runId)/artifacts"
        guard let url = URL(string: urlString) else { throw GitHubAPIError.invalidResponse }
        let request = try GitHubAuth.shared.authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
        let decoded = try JSONDecoder().decode(GitHubArtifactsResponse.self, from: data)
        return decoded.artifacts.filter { !$0.expired && $0.name.lowercased().hasSuffix(".ipa") }
    }

    func downloadArtifact(_ artifact: GitHubArtifact, repository: GitHubRepository) async throws -> Data {
        guard let url = URL(string: artifact.archiveDownloadURL) else { throw GitHubAPIError.invalidResponse }
        let request = try GitHubAuth.shared.authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
        return data
    }

    // MARK: - Validation

    static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        switch http.statusCode {
        case 200..<300: return
        case 401: throw GitHubAuthError.notConnected
        case 403 where http.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0":
            throw GitHubAPIError.rateLimited
        default: throw GitHubAPIError.http(http.statusCode)
        }
    }
}

enum GitHubAPIError: LocalizedError {
    case invalidResponse, rateLimited, http(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "GitHub returned an unexpected response."
        case .rateLimited: return "GitHub API rate limit reached. Try again later."
        case .http(let code): return "GitHub request failed (HTTP \(code))."
        }
    }
}
