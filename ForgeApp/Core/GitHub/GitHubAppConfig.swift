import Foundation

/// Central configuration for GitHub integration.
/// Configure GITHUB_OAUTH_CLIENT_ID in Info.plist with the public Client ID of
/// the iForge GitHub OAuth App. A client secret is never embedded in iOS apps.
enum GitHubAppConfig {
    static let workflowFileName = "iforge-build.yml"
    static let workflowPath = ".github/workflows/\(workflowFileName)"
    static let apiVersion = "2022-11-28"

    static var oauthClientID: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "GITHUB_OAUTH_CLIENT_ID") as? String,
              !value.isEmpty,
              !value.hasPrefix("YOUR_") else { return nil }
        return value
    }
}
