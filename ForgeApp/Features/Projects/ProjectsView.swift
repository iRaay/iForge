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
                    ForgeEmptyState(icon: ForgeSymbol.github, title: "Connect GitHub", message: "Sign in from Settings to see your repositories.")
                } else if isLoading {
                    ProgressView("Loading repositories…")
                        .controlSize(.large)
                } else if let errorMessage {
                    ForgeEmptyState(icon: ForgeSymbol.error, title: "Could Not Load Projects", message: LocalizedStringKey(errorMessage))
                } else if filtered.isEmpty {
                    ForgeEmptyState(icon: ForgeSymbol.projects, title: query.isEmpty ? "No Repositories" : "No Matches", message: query.isEmpty ? "This account has no repositories yet." : "Try a different search.")
                } else {
                    projectList
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SourceSelectionView() } label: {
                        Image(systemName: ForgeSymbol.add)
                    }
                    .accessibilityLabel("New Build")
                }
            }
            .searchable(text: $query, prompt: "Search repositories")
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private var projectList: some View {
        List {
            Section {
                ForEach(filtered) { repository in
                    NavigationLink { BuildConfigView(repository: repository) } label: {
                        HStack(spacing: 13) {
                            Image(systemName: repository.isPrivate ? "lock.fill" : ForgeSymbol.github)
                                .font(.title3)
                                .foregroundStyle(ForgeDesign.accent)
                                .frame(width: 42, height: 42)
                                .background(ForgeDesign.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(repository.name).font(.headline)
                                Text(repository.fullName).font(.caption).foregroundStyle(.secondary)
                                Text("\(repository.defaultBranch) · \(repository.isPrivate ? String(localized: "Private") : String(localized: "Public"))")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("My Repositories")
            } footer: {
                Text("Select a project to configure and start a build.")
            }
        }
        .listStyle(.insetGrouped)
    }

    private func load() async {
        guard auth.isConnected else { return }
        isLoading = repositories.isEmpty
        errorMessage = nil
        defer { isLoading = false }
        do { repositories = try await GitHubAPI.shared.fetchAuthenticatedUserRepositories() }
        catch { errorMessage = error.localizedDescription }
    }
}
