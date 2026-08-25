import Foundation

@MainActor
final class GitHubAPI: ObservableObject {
    static let shared = GitHubAPI()

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
