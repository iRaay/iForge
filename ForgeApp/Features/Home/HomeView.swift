import SwiftUI

struct ContentView: View {
    @AppStorage(OnboardingGate.key) private var onboardingCompleted = false
    @State private var selectedTab = 0

    var body: some View {
        if onboardingCompleted {
            TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            ProjectsView()
                .tabItem { Label("Projects", systemImage: "folder.fill") }
                .tag(1)

            BuildsView()
                .tabItem { Label("Builds", systemImage: "hammer.fill") }
                .tag(2)

            IPAFilesView()
                .tabItem { Label("IPA Files", systemImage: "archivebox.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(.purple)
        } else {
            OnboardingView()
        }
    }
}
