import Foundation

@MainActor
final class GitHubAuth: ObservableObject {
    static let shared = GitHubAuth()

    @Published private(set) var user: GitHubUser?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let tokenStore = KeychainStore.shared

    var isConnected: Bool { user != nil }
    var isConfigured: Bool { GitHubAppConfig.oauthClientID != nil }

    private init() { }

    func restoreSession() async {
        guard let token = tokenStore.load(), !token.isEmpty else { return }
        do {
            user = try await fetchUser(token: token)
        } catch {
            tokenStore.delete()
        }
    }

    func beginDeviceAuthorization() async throws -> GitHubDeviceCodeResponse {
        guard let clientID = GitHubAppConfig.oauthClientID else {
            throw GitHubAuthError.notConfigured
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var request = URLRequest(url: URL(string: "https://github.com/login/device/code")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formData([
            "client_id": clientID,
            "scope": "repo workflow read:user"
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode(GitHubDeviceCodeResponse.self, from: data)
    }

    func completeDeviceAuthorization(_ device: GitHubDeviceCodeResponse) async throws {
        guard let clientID = GitHubAppConfig.oauthClientID else {
            throw GitHubAuthError.notConfigured
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let deadline = Date().addingTimeInterval(TimeInterval(device.expiresIn))
        let interval = UInt64(max(device.interval ?? 5, 5))
        while Date() < deadline {
            try await Task.sleep(for: .seconds(interval))
            var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = formData([
                "client_id": clientID,
                "device_code": device.deviceCode,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response)
            let result = try JSONDecoder().decode(GitHubOAuthTokenResponse.self, from: data)
            if let token = result.accessToken, !token.isEmpty {
                let account = try await fetchUser(token: token)
                tokenStore.save(token)
                user = account
                return
            }
            switch result.error {
            case "authorization_pending", "slow_down": continue
            case "access_denied": throw GitHubAuthError.accessDenied
            case "expired_token": throw GitHubAuthError.expired
            default: throw GitHubAuthError.server(result.errorDescription ?? result.error ?? "Unknown GitHub authorization error.")
            }
        }
        throw GitHubAuthError.expired
    }

    func disconnect() {
        tokenStore.delete()
        user = nil
        errorMessage = nil
    }

    func authorizedRequest(url: URL, method: String = "GET") throws -> URLRequest {
        guard let token = tokenStore.load(), !token.isEmpty else { throw GitHubAuthError.notConnected }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue(GitHubAppConfig.apiVersion, forHTTPHeaderField: "X-GitHub-Api-Version")
        return request
    }

    private func fetchUser(token: String) async throws -> GitHubUser {
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue(GitHubAppConfig.apiVersion, forHTTPHeaderField: "X-GitHub-Api-Version")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode(GitHubUser.self, from: data)
    }

    private func formData(_ values: [String: String]) -> Data? {
        values.map { key, value in
            "\(key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)"
        }.joined(separator: "&").data(using: .utf8)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw GitHubAuthError.server("GitHub did not accept the request.")
        }
    }
}

enum GitHubAuthError: LocalizedError {
    case notConfigured, notConnected, accessDenied, expired, server(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "GitHub sign-in is not configured for this app build."
        case .notConnected: return "Connect GitHub to continue."
        case .accessDenied: return "GitHub authorization was denied."
        case .expired: return "The GitHub sign-in code expired. Try again."
        case .server(let message): return message
        }
    }
}
