import Foundation

@MainActor
final class BuildService: ObservableObject {
    @Published private(set) var builds: [BuildRecord] = []

    /// The workflow will be installed into the selected user's repository after
    /// GitHub OAuth is implemented. This placeholder deliberately performs no
    /// remote build and gives the UI a single service boundary to target.
    func start(_ request: BuildRequest) async throws {
        throw BuildServiceError.authenticationRequired
    }

    func refresh() async {
        // GitHub-backed history is added with OAuth in the next milestone.
    }
}

enum BuildServiceError: LocalizedError {
    case authenticationRequired

    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Connect GitHub to install iForge in a repository and start builds."
        }
    }
}
