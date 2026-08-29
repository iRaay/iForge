import SwiftUI
import UIKit

struct IPAFilesView: View {
    @State private var files: [SavedIPA] = []

    var body: some View {
        NavigationStack {
            Group {
                if files.isEmpty {
                    ForgeEmptyState(icon: ForgeSymbol.ipa, title: "No IPA Files", message: "IPAs from successful builds are saved here after download.")
                } else {
                    fileList
                }
            }
            .navigationTitle("IPA Files")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { loadSaved() } label: { Image(systemName: ForgeSymbol.refresh) }
                        .accessibilityLabel("Refresh IPA files")
                }
            }
            .refreshable { loadSaved() }
            .task { loadSaved() }
        }
    }

    private var fileList: some View {
        List {
            Section("Downloaded") {
                ForEach(files) { file in
                    NavigationLink { IPADetailView(saved: file) } label: {
                        HStack(spacing: 13) {
                            Image(systemName: ForgeSymbol.ipa)
                                .font(.title3).foregroundStyle(ForgeDesign.accent)
                                .frame(width: 42, height: 42)
                                .background(ForgeDesign.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.name).font(.headline)
                                Text("\(file.sizeString) · \(file.date.relative)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { delete(file) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("IPAFiles", isDirectory: true)
    }

    struct SavedIPA: Identifiable {
        let url: URL
        var id: String { url.lastPathComponent }
        var name: String { url.deletingPathExtension().lastPathComponent }
        var date: Date { (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date) ?? Date() }
        var sizeString: String {
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        }
    }

    static func savedFiles() -> [SavedIPA] {
        let dir = documentsDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let urls = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        return urls.filter { $0.pathExtension.lowercased() == "ipa" }.map(SavedIPA.init(url:)).sorted { $0.date > $1.date }
    }

    private func loadSaved() { files = Self.savedFiles() }
    private func delete(_ file: SavedIPA) { try? FileManager.default.removeItem(at: file.url); loadSaved() }
}

struct IPADetailView: View {
    let saved: IPAFilesView.SavedIPA
    @State private var showingShare = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: ForgeSymbol.ipa).font(.system(size: 72)).foregroundStyle(ForgeDesign.accent)
            Text(saved.url.lastPathComponent).font(.title3.bold()).multilineTextAlignment(.center)
            Text(saved.sizeString).foregroundStyle(.secondary)
            Button("Share", systemImage: ForgeSymbol.share) { showingShare = true }.buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding().navigationTitle(saved.name).navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShare) { ShareSheet(items: [saved.url]) }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
