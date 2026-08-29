import SwiftUI

struct BuildsView: View {
    @StateObject private var service = BuildService.shared
    @State private var filter: BuildState?

    private var filtered: [TrackedBuild] {
        guard let filter else { return service.trackedBuilds }
        return service.trackedBuilds.filter { service.state(for: $0) == filter }
    }

    var body: some View {
        NavigationStack {
            Group {
                if service.trackedBuilds.isEmpty {
                    ForgeEmptyState(icon: ForgeSymbol.builds, title: "No Builds Yet", message: "Start a build from the Projects tab.")
                } else {
                    buildList
                }
            }
            .navigationTitle("Builds")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await service.refresh() } } label: {
                        Image(systemName: ForgeSymbol.refresh)
                    }
                    .accessibilityLabel("Refresh builds")
                }
            }
            .refreshable { await service.refresh() }
            .task { await service.refresh() }
        }
    }

    private var buildList: some View {
        List {
            Section {
                Picker("Filter", selection: $filter) {
                    Text("All").tag(BuildState?.none)
                    ForEach(BuildState.allCases, id: \.self) { state in
                        Text(state.title).tag(BuildState?.some(state))
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section("Build History") {
                ForEach(filtered) { build in
                    NavigationLink { BuildDetailView(build: build) } label: {
                        BuildRow(build: build)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct BuildRow: View {
    @ObservedObject var service = BuildService.shared
    let build: TrackedBuild

    var body: some View {
        HStack(spacing: 13) {
            let state = service.state(for: build)
            Image(systemName: iconName(state))
                .font(.title3.weight(.semibold))
                .foregroundStyle(iconColor(state))
                .frame(width: 40, height: 40)
                .background(iconColor(state).opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(build.repositoryFullName.split(separator: "/").last.map(String.init) ?? build.repositoryFullName)
                    .font(.headline)
                Text("\(build.branch) · \(build.configuration)")
                    .font(.caption).foregroundStyle(.secondary)
                Text(build.startedAt.relative).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 4)
            ForgeStatusBadge(title: LocalizedStringKey(state.title), icon: iconName(state), color: iconColor(state))
        }
        .padding(.vertical, 5)
    }

    private func iconName(_ state: BuildState) -> String {
        switch state {
        case .queued: return "clock.badge.questionmark"
        case .running: return ForgeSymbol.pipeline
        case .success: return ForgeSymbol.success
        case .failed: return ForgeSymbol.error
        }
    }

    private func iconColor(_ state: BuildState) -> Color {
        switch state {
        case .queued: return .secondary
        case .running: return ForgeDesign.warning
        case .success: return ForgeDesign.success
        case .failed: return ForgeDesign.danger
        }
    }
}
