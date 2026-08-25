import SwiftUI

struct BuildConfigView: View {
    let repository: GitHubRepository

    @State private var branch: String
    @State private var configuration: BuildConfiguration = .release
    @State private var cleanBuild = true
    @State private var allowPackagePlugins = false
    @State private var isStarting = false
    @State private var statusMessage: String?

    init(repository: GitHubRepository) {
        self.repository = repository
        _branch = State(initialValue: repository.defaultBranch)
    }

    var body: some View {
        Form {
            Section("Repository") {
                LabeledContent("Project", value: repository.fullName)
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
                        HStack { ProgressView(); Text("Starting…") }
                    } else {
                        Label("Start Build", systemImage: "play.fill")
                    }
                }
                .disabled(isStarting || branch.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let statusMessage {
                Section { Text(statusMessage).foregroundStyle(.secondary) }
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
            try await BuildService.shared.start(request)
            statusMessage = "Build queued in \(repository.fullName)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
