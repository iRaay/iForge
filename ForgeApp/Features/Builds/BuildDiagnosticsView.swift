import SwiftUI

struct BuildDiagnosticsView: View {
    let build: TrackedBuild
    @ObservedObject private var service = BuildService.shared
    @State private var showingLogs = false

    private var diagnostics: [BuildDiagnostic] { service.diagnostics[build.runId] ?? [] }
    private var logs: [BuildLogEntry] { service.logs[build.runId] ?? [] }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: diagnostics.contains { $0.severity == .error } ? ForgeSymbol.error : ForgeSymbol.success)
                        .font(.title2).foregroundStyle(diagnostics.contains { $0.severity == .error } ? ForgeDesign.danger : ForgeDesign.success)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(diagnostics.isEmpty ? "Build Health" : "Diagnostics").font(.headline)
                        Text(diagnostics.isEmpty ? "No diagnostics have been reported yet." : "Warnings and errors are separated by severity.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 5)
            }

            if diagnostics.isEmpty {
                Section { ForgeEmptyState(icon: ForgeSymbol.info, title: "No Diagnostics", message: "Build warnings and errors will appear here.") }
            } else {
                Section("Build Diagnostics") {
                    ForEach(diagnostics) { diagnostic in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: diagnostic.severity.symbol).foregroundStyle(color(diagnostic.severity))
                            VStack(alignment: .leading, spacing: 3) {
                                HStack { Text(diagnostic.title).font(.subheadline.weight(.semibold)); Spacer(); Text(diagnostic.source).font(.caption2).foregroundStyle(.tertiary) }
                                Text(diagnostic.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button { showingLogs = true } label: {
                    Label("View Activity Log (\(logs.count))", systemImage: ForgeSymbol.queue)
                }
            }
        }
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingLogs) { BuildLogView(build: build) }
    }

    private func color(_ severity: DiagnosticSeverity) -> Color {
        switch severity { case .info: return .blue; case .warning: return ForgeDesign.warning; case .error: return ForgeDesign.danger; case .success: return ForgeDesign.success }
    }
}

struct BuildLogView: View {
    let build: TrackedBuild
    @ObservedObject private var service = BuildService.shared

    var body: some View {
        NavigationStack {
            List(service.logs[build.runId] ?? []) { entry in
                HStack(alignment: .top, spacing: 10) {
                    Text(entry.timestamp, style: .time).font(.caption2.monospaced()).foregroundStyle(.tertiary)
                    Image(systemName: entry.level.symbol).foregroundStyle(color(entry.level))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.message).font(.caption.monospaced()).textSelection(.enabled)
                        Text(entry.source).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 3)
            }
            .navigationTitle("Activity Log")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Clear", role: .destructive) { service.clearLogs(runId: build.runId) } } }
        }
    }

    private func color(_ severity: DiagnosticSeverity) -> Color {
        switch severity { case .info: return .blue; case .warning: return ForgeDesign.warning; case .error: return ForgeDesign.danger; case .success: return ForgeDesign.success }
    }
}
