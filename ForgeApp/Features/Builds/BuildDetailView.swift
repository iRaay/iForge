import SwiftUI

struct BuildDetailView: View {
    let build: TrackedBuild
    @StateObject private var service = BuildService.shared

    private var state: BuildState { service.state(for: build) }
    private var jobs: [BuildJob] { service.jobDetails[build.runId] ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard
                statusCard
                if state == .failed { failureCard }
                pipelineCard
                if state == .success { ipaButton }
            }
            .padding(ForgeDesign.pagePadding)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Build #\(String(build.runId).suffix(6))")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await refresh() }
        .task {
            await refresh()
            while state == .running || state == .queued {
                try? await Task.sleep(for: .seconds(10)); await refresh()
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(build.repositoryFullName, systemImage: ForgeSymbol.projects).font(.headline)
                Spacer(); Text(build.configuration).font(.caption.weight(.semibold)).foregroundStyle(ForgeDesign.accent)
            }
            Divider()
            HStack {
                Label(build.branch, systemImage: ForgeSymbol.branch)
                Spacer(); Text(build.startedAt.relative).font(.caption).foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .forgeCard()
    }

    private var statusCard: some View {
        HStack(spacing: 13) {
            Image(systemName: statusIcon).font(.title).foregroundStyle(statusColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(state.title).font(.title3.bold())
                Text(state == .running ? "GitHub Actions is building your project." : state == .queued ? "Waiting for a macOS runner." : state == .success ? "Your IPA is ready to download." : "The build needs attention.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .forgeCard()
    }

    private var failureCard: some View {
        Label("Open the pipeline steps below for the first failed stage and its diagnostic details.", systemImage: ForgeSymbol.warning)
            .font(.subheadline).foregroundStyle(ForgeDesign.warning).forgeCard()
    }

    private var pipelineCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Pipeline", systemImage: ForgeSymbol.pipeline).font(.headline).padding(.bottom, 8)
            if jobs.isEmpty {
                HStack { ProgressView(); Text("Loading pipeline status…").foregroundStyle(.secondary) }
                    .padding(.vertical, 12)
            }
            ForEach(jobs) { job in
                VStack(alignment: .leading, spacing: 7) {
                    Text(job.name).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    ForEach(job.steps.filter { !$0.name.contains("Set up") && !$0.name.contains("Post ") && !$0.name.contains("Complete") }) { step in
                        HStack(spacing: 10) {
                            Image(systemName: step.didFail ? ForgeSymbol.error : step.isDone ? ForgeSymbol.success : step.status == "in_progress" ? "arrow.triangle.2.circlepath" : "circle.dashed")
                                .foregroundStyle(step.didFail ? ForgeDesign.danger : step.isDone ? ForgeDesign.success : ForgeDesign.warning)
                            Text(step.name).font(.subheadline)
                            Spacer()
                            if step.status == "in_progress" { ProgressView() }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .forgeCard()
    }

    private var ipaButton: some View {
        NavigationLink { IPADownloadView(build: build) } label: {
            Label("View IPA Files", systemImage: ForgeSymbol.ipa).frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent).tint(ForgeDesign.accent)
    }

    private var statusIcon: String {
        switch state { case .queued: return "clock.badge.questionmark"; case .running: return ForgeSymbol.pipeline; case .success: return ForgeSymbol.success; case .failed: return ForgeSymbol.error }
    }
    private var statusColor: Color {
        switch state { case .queued: return .secondary; case .running: return ForgeDesign.warning; case .success: return ForgeDesign.success; case .failed: return ForgeDesign.danger }
    }
    private func refresh() async {
        guard let repo = decodedRepository else { return }
        service.cache(repository: repo); await service.refresh()
    }
    private var decodedRepository: GitHubRepository? { .init(id: 0, fullName: build.repositoryFullName, name: build.repositoryFullName.split(separator: "/").last.map(String.init) ?? "", defaultBranch: build.branch, isPrivate: true) }
}
