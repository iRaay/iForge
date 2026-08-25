import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct IPAFilesView: View {
    @StateObject private var service = BuildService.shared
    @State private var files: [SavedIPA] = []

    var body: some View {
        NavigationStack {
            Group {
                if files.isEmpty {
                    ContentUnavailableView("No IPA Files", systemImage: "archivebox",
                        description: Text("IPAs from successful builds are saved here automatically after download."))
                } else {
                    fileList
                }
            }
            .navigationTitle("IPA Files")
            .refreshable { loadSaved() }
            .task { loadSaved() }
        }
    }

    private var fileList: some View {
        List(files) { file in
            NavigationLink {
                IPADetailView(saved: file)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.zipper").font(.title2)
                        .foregroundStyle(.purple)
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(file.name).font(.headline)
                        Text("\(file.sizeString) · \(file.date.relative)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.insetGrouped)
    }

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("IPAFiles", isDirectory: true)
    }

    struct SavedIPA: Identifiable {
        let url: URL
        var id: String { url.lastPathComponent }
        var name: String { url.deletingPathExtension().lastPathComponent }
        var date: Date {
            (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date) ?? Date()
        }
        var sizeString: String {
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        }
    }

    static func savedFiles() -> [SavedIPA] {
        let dir = documentsDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let urls = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        return urls.filter { $0.pathExtension == "ipa" }
            .map(SavedIPA.init(url:))
            .sorted { $0.date > $1.date }
    }

    private func loadSaved() { files = Self.savedFiles() }
}

struct IPADetailView: View {
    let saved: IPAFilesView.SavedIPA
    @State private var showingShare = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.zipper").font(.system(size: 72)).foregroundStyle(.purple)
            Text(saved.url.lastPathComponent).font(.title3.bold())
            Text(saved.sizeString).foregroundStyle(.secondary)

            Button("Share", systemImage: "square.and.arrow.up") { showingShare = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .navigationTitle(saved.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShare) {
            ShareSheet(items: [saved.url])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
