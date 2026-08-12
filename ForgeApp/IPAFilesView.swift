import SwiftUI

struct IPAItem: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
    let size: String
    let build: Int
}

struct IPAFilesView: View {
    @State private var query = ""

    private let files = [
        IPAItem(name: "Navi", fileName: "Navi.ipa", size: "18.4 MB", build: 42),
        IPAItem(name: "ChatGPT", fileName: "ChatGPT.ipa", size: "92.1 MB", build: 128),
        IPAItem(name: "YouTube", fileName: "YouTube.ipa", size: "201.3 MB", build: 30)
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFiles) { file in
                    NavigationLink {
                        IPADetailView(file: file)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "doc.zipper")
                                .font(.title2)
                                .frame(width: 46, height: 46)
                                .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.name).font(.headline)
                                Text(file.fileName).font(.subheadline).foregroundStyle(.secondary)
                                Text("Build \(file.build) · \(file.size)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(.purple)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("IPA Files")
            .searchable(text: $query, prompt: "Search IPA files")
        }
    }

    private var filteredFiles: [IPAItem] {
        guard !query.isEmpty else { return files }
        return files.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.fileName.localizedCaseInsensitiveContains(query) }
    }
}

struct IPADetailView: View {
    let file: IPAItem

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.zipper")
                .font(.system(size: 76))
                .foregroundStyle(.purple)
            Text(file.fileName).font(.title2.bold())
            Text(file.size).foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("App Name", value: file.name)
                LabeledContent("Build", value: "\(file.build)")
                LabeledContent("Status", value: "Build Successful")
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

            HStack {
                Button("Download IPA", systemImage: "arrow.down") {}
                    .buttonStyle(.borderedProminent)
                Button("Open in Feather", systemImage: "signature") {}
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding()
        .navigationTitle(file.fileName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("GitHub") {
                    LabeledContent("Account", value: "iRaay")
                    Button("Disconnect", role: .destructive) {}
                }
                Section("Build Defaults") {
                    LabeledContent("Configuration", value: "Release")
                    LabeledContent("Minimum iOS", value: "17.4+")
                }
                Section("Notifications") {
                    Toggle("Build Completed", isOn: .constant(true))
                    Toggle("Build Failed", isOn: .constant(true))
                }
                Section("About") {
                    LabeledContent("Forge", value: "1.0.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
