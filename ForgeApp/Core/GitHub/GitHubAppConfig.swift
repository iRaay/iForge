import Foundation

/// Central configuration for GitHub integration.
/// The app intentionally has no fixed account or engine repository. Once OAuth
/// is added, the selected repository owns its iForge workflow and build runs.
enum GitHubAppConfig {
    static let workflowFileName = "iforge-build.yml"
    static let workflowPath = ".github/workflows/\(workflowFileName)"
    static let apiVersion = "2022-11-28"
}
