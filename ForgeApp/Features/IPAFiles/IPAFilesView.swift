import SwiftUI

struct IPAFilesView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No IPA Files",
                systemImage: "archivebox",
                description: Text("IPAs from successful builds will be available here.")
            )
            .navigationTitle("IPA Files")
        }
    }
}
