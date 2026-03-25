import SwiftUI

@main
struct TABAIApp: App {
    @StateObject private var appEnvironment = AppEnvironment(
        keychain: KeychainStore(),
        featureFlags: FeatureFlags(useTABAI: false)
    )
    @AppStorage("tai.themePreference") private var themePreference = "system"
    @AppStorage("tai.languagePreference") private var languagePreference = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appEnvironment)
                .preferredColorScheme(preferredColorScheme)
                .environment(\.locale, preferredLocale)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch themePreference.lowercased() {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    private var preferredLocale: Locale {
        switch languagePreference.lowercased() {
        case "en":
            return Locale(identifier: "en")
        case "tr":
            return Locale(identifier: "tr")
        default:
            return .autoupdatingCurrent
        }
    }
}
