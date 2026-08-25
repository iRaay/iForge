import SwiftUI

struct ProjectsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Connect GitHub",
                systemImage: "folder.badge.questionmark",
                description: Text("Your repositories will appear here after secure GitHub sign-in is added.")
            )
            .navigationTitle("Projects")
        }
    }
}
