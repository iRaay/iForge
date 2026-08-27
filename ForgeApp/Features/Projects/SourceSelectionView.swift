import SwiftUI

struct SourceSelectionView: View {
    enum Source: String, CaseIterable, Identifiable {
        case github, gitURL, zip
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .github: return "GitHub Repository"
            case .gitURL: return "Any Git URL"
            case .zip: return "Upload ZIP Project"
            }
        }
        var icon: String {
            switch self { case .github: return "network"; case .gitURL: return "link"; case .zip: return "doc.zipper" }
        }
        var detail: LocalizedStringKey {
            switch self {
            case .github: return "Build directly from a repository you can access. No fork required."
            case .gitURL: return "GitLab, Bitbucket, or self-hosted Git over HTTPS."
            case .zip: return "Upload an Xcode project from this device. Coming soon."
            }
        }
    }

    @State private var source: Source = .github
    @State private var showGitURL = false
    @State private var showZIPImporter = false

    var body: some View {
        List {
            Section("Choose Source") {
                ForEach(Source.allCases) { item in
                    Button { select(item) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: item.icon).font(.title2).foregroundStyle(.purple).frame(width: 34)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(.headline)
                                Text(item.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if source == item { Image(systemName: "checkmark.circle.fill").foregroundStyle(.purple) }
                        }
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                }
            }

            if source == .github {
                Section {
                    NavigationLink { ProjectsView() } label: {
                        Label("Select GitHub Repository", systemImage: "folder.fill")
                    }
                } footer: {
                    Text("iForge installs its workflow directly into the selected repository. You need write access; a fork is not required.")
                }
            }
        }
        .navigationTitle("New Build")
        .sheet(isPresented: $showGitURL) { GitURLBuildView() }
        .fileImporter(isPresented: $showZIPImporter, allowedContentTypes: [.zip], allowsMultipleSelection: false) { _ in }
    }

    private func select(_ item: Source) {
        source = item
        if item == .gitURL { showGitURL = true }
        if item == .zip { showZIPImporter = true }
    }
}

struct GitURLBuildView: View {
    @State private var url = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Git Repository") {
                    TextField("https://…/project.git", text: $url)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                Section {
                    Text("Public HTTPS Git URLs are supported first. Private Git credentials will be added through secure provider authentication.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Git URL")
        }
    }
}
