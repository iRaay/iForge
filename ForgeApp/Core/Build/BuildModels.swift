import Foundation

struct BuildRequest: Hashable {
    let repository: GitHubRepository
    var branch: String
    var configuration: BuildConfiguration
    var cleanBuild: Bool
    var allowPackagePlugins: Bool
}

enum BuildConfiguration: String, Codable, CaseIterable, Identifiable {
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


enum DiagnosticSeverity: String, Codable, CaseIterable, Identifiable {
    case info, warning, error, success
    var id: String { rawValue }
    var title: String {
        switch self { case .info: return "Info"; case .warning: return "Warning"; case .error: return "Error"; case .success: return "Success" }
    }
    var symbol: String {
        switch self { case .info: return ForgeSymbol.info; case .warning: return ForgeSymbol.warning; case .error: return ForgeSymbol.error; case .success: return ForgeSymbol.success }
    }
}

struct BuildDiagnostic: Identifiable, Codable, Hashable {
    let id: UUID
    let severity: DiagnosticSeverity
    let title: String
    let detail: String
    let source: String
    let timestamp: Date

    init(severity: DiagnosticSeverity, title: String, detail: String, source: String, timestamp: Date = Date()) {
        self.id = UUID(); self.severity = severity; self.title = title; self.detail = detail; self.source = source; self.timestamp = timestamp
    }
}

struct BuildLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let level: DiagnosticSeverity
    let message: String
    let source: String

    init(level: DiagnosticSeverity, message: String, source: String, timestamp: Date = Date()) {
        self.id = UUID(); self.timestamp = timestamp; self.level = level; self.message = message; self.source = source
    }
}
