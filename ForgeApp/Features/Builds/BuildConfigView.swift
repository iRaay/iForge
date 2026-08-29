import SwiftUI

struct BuildConfigView: View {
    let repository: GitHubRepository

    @State private var branch: String
    @State private var configuration: BuildConfiguration = .release
    @State private var cleanBuild = true
    @State private var allowPackagePlugins = false
    @State private var isStarting = false
    @State private var statusMessage: String?
    @State private var isSuccess = false
    @StateObject private var service = BuildService.shared

    init(repository: GitHubRepository) {
        self.repository = repository
        let saved = BuildService.shared.rememberedSettings(for: repository)
        _branch = State(initialValue: saved?.branch ?? repository.defaultBranch)
        _configuration = State(initialValue: saved?.configuration ?? .release)
        _cleanBuild = State(initialValue: saved?.clean ?? true)
        _allowPackagePlugins = State(initialValue: saved?.plugins ?? false)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                projectHeader
                sourceCard
                configurationCard
                safetyNote
                startButton
                if let statusMessage { resultCard(statusMessage) }
            }
            .padding(ForgeDesign.pagePadding)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("New Build")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Build Workspace").font(.title2.bold())
            Text("Configure a reproducible build for this project.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Source", systemImage: ForgeSymbol.projects).font(.headline)
            HStack(spacing: 12) {
                Image(systemName: repository.isPrivate ? "lock.fill" : ForgeSymbol.github)
                    .font(.title2).foregroundStyle(ForgeDesign.accent)
                    .frame(width: 44, height: 44)
                    .background(ForgeDesign.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(repository.fullName).font(.headline)
                    Text(repository.isPrivate ? "Private repository" : "Public repository")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Divider()
            HStack {
                Image(systemName: ForgeSymbol.branch).foregroundStyle(ForgeDesign.accent)
                TextField("Branch", text: $branch)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            }
        }
        .forgeCard()
    }

    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Xcode Build Type", systemImage: ForgeSymbol.code).font(.headline)
            Picker("Xcode Build Type", selection: $configuration) {
                ForEach(BuildConfiguration.allCases) { option in Text(option.rawValue).tag(option) }
            }
            .pickerStyle(.segmented)
            Toggle(isOn: $cleanBuild) {
                Label("Clean Build", systemImage: "sparkles.rectangle.stack.fill")
            }
            Toggle(isOn: $allowPackagePlugins) {
                Label("Allow Package Plugins", systemImage: "shippingbox.and.arrow.backward.fill")
            }
        }
        .forgeCard()
    }

    private var safetyNote: some View {
        Label("Package plugin validation is disabled by default. Enable it only when the project requires trusted build plugins.", systemImage: ForgeSymbol.info)
            .font(.caption).foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private var startButton: some View {
        Button { Task { await start() } } label: {
            HStack {
                if isStarting { ProgressView().tint(.white); Text("Starting build…") }
                else { Image(systemName: ForgeSymbol.play); Text("Start Build") }
            }
            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(ForgeDesign.accent)
        .disabled(isStarting || branch.trimmingCharacters(in: .whitespaces).isEmpty)
        .accessibilityHint("Installs the iForge workflow and starts an Xcode build")
    }

    private func resultCard(_ message: String) -> some View {
        Label(message, systemImage: isSuccess ? ForgeSymbol.success : ForgeSymbol.warning)
            .foregroundStyle(isSuccess ? ForgeDesign.success : ForgeDesign.danger)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()
    }

    private func start() async {
        isStarting = true; statusMessage = nil
        defer { isStarting = false }
        let request = BuildRequest(repository: repository, branch: branch.trimmingCharacters(in: .whitespaces), configuration: configuration, cleanBuild: cleanBuild, allowPackagePlugins: allowPackagePlugins)
        do {
            service.cache(repository: repository)
            try await service.start(request)
            isSuccess = true
            statusMessage = "Build queued. Track progress in Builds."
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            isSuccess = false; statusMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
