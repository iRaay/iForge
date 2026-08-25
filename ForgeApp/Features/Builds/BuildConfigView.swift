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
        _branch = State(initialValue: repository.defaultBranch)
        if let saved = BuildService.shared.rememberedSettings(for: repository) {
            _branch = State(initialValue: saved.branch)
            _configuration = State(initialValue: saved.configuration)
            _cleanBuild = State(initialValue: saved.clean)
            _allowPackagePlugins = State(initialValue: saved.plugins)
        }
    }

    var body: some View {
        Form {
            Section("Repository") {
                LabeledContent("Project", value: repository.fullName)
                LabeledContent("Visibility", value: repository.isPrivate ? "Private" : "Public")
                TextField("Branch", text: $branch)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Build") {
                Picker("Configuration", selection: $configuration) {
                    ForEach(BuildConfiguration.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Toggle("Clean Build", isOn: $cleanBuild)
                Toggle("Allow Package Plugins", isOn: $allowPackagePlugins)
            }

            Section {
                Button {
                    Task { await start() }
                } label: {
                    if isStarting {
                        HStack { ProgressView(); Text("Installing workflow and starting…") }
                    } else {
                        Label("Start Build", systemImage: "play.fill")
                    }
                }
                .disabled(isStarting || branch.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let statusMessage {
                Section {
                    Label(statusMessage, systemImage: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isSuccess ? .green : .red)
                }
            }
        }
        .navigationTitle("New Build")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func start() async {
        isStarting = true
        statusMessage = nil
        defer { isStarting = false }

        let request = BuildRequest(
            repository: repository,
            branch: branch.trimmingCharacters(in: .whitespaces),
            configuration: configuration,
            cleanBuild: cleanBuild,
            allowPackagePlugins: allowPackagePlugins
        )

        do {
            BuildService.shared.cache(repository: repository)
            try await BuildService.shared.start(request)
            isSuccess = true
            statusMessage = "Build queued in \(repository.fullName). Track it in the Builds tab."
        } catch {
            isSuccess = false
            statusMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
