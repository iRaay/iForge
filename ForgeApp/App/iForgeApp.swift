import SwiftUI

@main
struct iForgeApp: App {
    @AppStorage("appLanguage") private var appLanguage = "system"
    @AppStorage("appTheme") private var appTheme = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: appLanguage == "system" ? Locale.current.identifier : appLanguage))
                .preferredColorScheme(selectedColorScheme)
        }
    }

    private var selectedColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
