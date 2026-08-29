import SwiftUI

struct ContentView: View {
    @AppStorage(OnboardingGate.key) private var onboardingCompleted = false
    @State private var selectedTab = 0

    var body: some View {
        if onboardingCompleted {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem { Label("Home", systemImage: ForgeSymbol.home) }.tag(0)
                ProjectsView()
                    .tabItem { Label("Projects", systemImage: ForgeSymbol.projects) }.tag(1)
                BuildsView()
                    .tabItem { Label("Builds", systemImage: ForgeSymbol.builds) }.tag(2)
                IPAFilesView()
                    .tabItem { Label("IPA Files", systemImage: ForgeSymbol.ipa) }.tag(3)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: ForgeSymbol.settings) }.tag(4)
            }
            .tint(ForgeDesign.accent)
        } else {
            OnboardingView()
        }
    }
}
