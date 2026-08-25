import SwiftUI

struct BuildDetailView: View {
    let build: TrackedBuild
    @StateObject private var service = BuildService.shared
    @State private var isRefreshing = false

    private var state: BuildState { service.state(for: build) }
    private var jobs: [BuildJob] { service.jobDetails[build.runId] ?? [] }

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Repository", value: build.repositoryFullName)
                LabeledContent("Branch", value: build.branch)
                LabeledContent("Configuration", value: build.configuration)
                LabeledContent("Started", value: build.startedAt.relative)
                HStack {
                    Text("Status")
                    Spacer()
                    Text(state.title).bold().foregroundStyle(stateColor)
                }
            }

            if state == .running || state == .queued {
                Section {
                    HStack { ProgressView(); Text("Build in progress…").foregroundStyle(.secondary) }
                }
            }

            ForEach(jobs) { job in
                Section("Pipeline — \(job.name)") {
                    ForEach(job.steps.filter { $0.name != "Set up job" && $0.name != "Post Checkout Project" && $0.name != "Complete job" }) { step in
                        HStack(spacing: 10) {
                            stepIcon(step)
                            Text(step.name)
                                .font(.subheadline)
                            Spacer()
                            if !step.isDone && !step.didFail && step.status == "in_progress" {
                                ProgressView()
                            }
                        }
                        .foregroundStyle(step.didFail ? .red : .primary)
                    }
                }
            }

            if state == .success {
                Section {
                    NavigationLink {
                        IPADownloadView(build: build)
                    } label: {
                        Label("View IPA Files", systemImage: "archivebox.fill")
                    }
                }
            }
        }
        .navigationTitle("Build #\(String(build.runId.suffix(6)))")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await refresh() }
        .task {
            await refresh()
            // Live-poll while the build is not finished.
            while state == .running || state == .queued {
                try? await Task.sleep(for: .seconds(10))
                await refresh()
            }
        }
    }

    private var stateColor: Color {
        switch state {
        case .queued: return .gray
        case .running: return .orange
        case .success: return .green
        case .failed: return .red
        }
    }

    private func stepIcon(_ step: BuildStep) -> some View {
        Group {
            if step.didFail { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
            else if step.isDone { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
            else { Image(systemName: "circle.dotted").foregroundStyle(.secondary) }
        }
    }

    private func refresh() async {
        guard let repo = decodedRepository else { return }
        BuildService.shared.cache(repository: repo)
        await service.refresh()
    }

    private var decodedRepository: GitHubRepository? {
        .init(id: 0, fullName: build.repositoryFullName,
              name: build.repositoryFullName.split(separator: "/").last.map(String.init) ?? "",
              defaultBranch: build.branch, isPrivate: true)
    }
}
