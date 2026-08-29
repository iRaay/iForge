import SwiftUI

struct BuildHealthBanner: View {
    let build: TrackedBuild
    @ObservedObject private var service = BuildService.shared

    private var warnings: [BuildDiagnostic] { (service.diagnostics[build.runId] ?? []).filter { $0.severity == .warning } }
    private var errors: [BuildDiagnostic] { (service.diagnostics[build.runId] ?? []).filter { $0.severity == .error } }

    var body: some View {
        NavigationLink { BuildDiagnosticsView(build: build) } label: {
            HStack(spacing: 11) {
                Image(systemName: errors.isEmpty ? (warnings.isEmpty ? ForgeSymbol.success : ForgeSymbol.warning) : ForgeSymbol.error)
                    .foregroundStyle(errors.isEmpty ? (warnings.isEmpty ? ForgeDesign.success : ForgeDesign.warning) : ForgeDesign.danger)
                VStack(alignment: .leading, spacing: 2) {
                    Text(errors.isEmpty ? (warnings.isEmpty ? "Build Health: Good" : "Build Health: Review warnings") : "Build Health: Needs attention")
                        .font(.subheadline.weight(.semibold))
                    Text("\(warnings.count) warnings · \(errors.count) errors")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.forward").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
