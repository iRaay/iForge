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
                    ContentUnavailableView("No Builds Yet", systemImage: "hammer",
                        description: Text("Start a build from the Projects tab."))
                } else {
                    buildList
                }
            }
            .navigationTitle("Builds")
            .refreshable { await service.refresh() }
            .task { await service.refresh() }
        }
    }

    private var buildList: some View {
        List {
            Picker("Filter", selection: $filter) {
                Text("All").tag(BuildState?.none)
                ForEach(BuildState.allCases, id: \.self) { state in
                    Text(state.title).tag(BuildState?.some(state))
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            ForEach(filtered) { build in
                NavigationLink {
                    BuildDetailView(build: build)
                } label: {
                    BuildRow(build: build)
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
        HStack(spacing: 12) {
            statusBadge
            VStack(alignment: .leading, spacing: 3) {
                Text(build.repositoryFullName.split(separator: "/").last.map(String.init) ?? build.repositoryFullName)
                    .font(.headline)
                Text("\(build.branch) · \(build.configuration) · \(build.startedAt.relative)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var statusBadge: some View {
        let state = service.state(for: build)
        return Image(systemName: iconName(state))
            .font(.title3)
            .foregroundStyle(iconColor(state))
            .frame(width: 34)
    }

    private func iconName(_ state: BuildState) -> String {
        switch state {
        case .queued: return "clock"
        case .running: return "hammer.fill"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private func iconColor(_ state: BuildState) -> Color {
        switch state {
        case .queued: return .gray
        case .running: return .orange
        case .success: return .green
        case .failed: return .red
        }
    }
}
