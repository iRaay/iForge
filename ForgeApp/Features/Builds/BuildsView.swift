import SwiftUI

struct BuildsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Builds Yet",
                systemImage: "hammer",
                description: Text("Build history will appear here after GitHub is connected.")
            )
            .navigationTitle("Builds")
        }
    }
}
