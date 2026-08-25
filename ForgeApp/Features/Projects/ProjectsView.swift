import SwiftUI

struct ProjectsView: View {
    @StateObject private var auth = GitHubAuth.shared
    @State private var repositories: [GitHubRepository] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var query = ""

    private var filtered: [GitHubRepository] {
        guard !query.isEmpty else { return repositories }
        return repositories.filter { $0.fullName.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !auth.isConnected {
                    ContentUnavailableView("Connect GitHub", systemImage: "person.badge.key",
                        description: Text("Sign in from Settings to see your repositories."))
                } else if isLoading {
                    ProgressView("Loading repositories…")
                } else if let error = errorMessage {
                    ContentUnavailableView("Could Not Load Projects", systemImage: "exclamationmark.triangle",
                        description: Text(error))
                } else if filtered.isEmpty {
                    ContentUnavailableView(query.isEmpty ? "No Repositories" : "No Matches",
                        systemImage: "folder",
                        description: Text(query.isEmpty ? "This account has no repositories yet." : "Try a different search."))
                } else {
                    repositoryList
                }
            }
            .navigationTitle("Projects")
            .searchable(text: $query, prompt: "Search repositories")
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private var repositoryList: some View {
        List(filtered) { repository in
            NavigationLink {
                BuildConfigView(repository: repository)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(repository.name).font(.headline)
                    Text(repository.fullName).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func load() async {
        guard auth.isConnected else { return }
        isLoading = repositories.isEmpty
        errorMessage = nil
        defer { isLoading = false }
        do {
            repositories = try await GitHubAPI.shared.fetchAuthenticatedUserRepositories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
