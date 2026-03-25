import Foundation
import Combine

// MARK: - Language Definition

struct AppLanguage: Identifiable, Hashable {
    let id: String // locale code
    let label: String
    let nativeLabel: String
    let isRTL: Bool

    init(_ id: String, _ label: String, _ nativeLabel: String, isRTL: Bool = false) {
        self.id = id
        self.label = label
        self.nativeLabel = nativeLabel
        self.isRTL = isRTL
    }

    var displayLabel: String {
        label == nativeLabel ? label : "\(label) — \(nativeLabel)"
    }
}

let supportedAppLanguages: [AppLanguage] = [
    AppLanguage("system", "System", "System"),
    AppLanguage("en", "English", "English"),
    AppLanguage("en-IN", "English (IN)", "English (IN)"),
    AppLanguage("en-GB", "English (UK)", "English (UK)"),
    AppLanguage("fr", "Fran\u{00E7}ais", "Fran\u{00E7}ais"),
    AppLanguage("fr-CA", "Fran\u{00E7}ais (CA)", "Fran\u{00E7}ais (CA)"),
    AppLanguage("de", "Deutsch", "Deutsch"),
    AppLanguage("de-AT", "Deutsch (AT)", "Deutsch (AT)"),
    AppLanguage("hi", "Hindi", "Hindi"),
    AppLanguage("it", "Italiano", "Italiano"),
    AppLanguage("ja", "Japanese", "Japanese"),
    AppLanguage("ko", "Korean", "Korean"),
    AppLanguage("pt", "Portugu\u{00EA}s", "Portugu\u{00EA}s"),
    AppLanguage("pt-BR", "Portugu\u{00EA}s (BR)", "Portugu\u{00EA}s (BR)"),
    AppLanguage("ru", "Russian", "Russian"),
    AppLanguage("es", "Espa\u{00F1}ol", "Espa\u{00F1}ol"),
    AppLanguage("es-419", "Espa\u{00F1}ol (LATAM)", "Espa\u{00F1}ol (LATAM)"),
    AppLanguage("tr", "T\u{00FC}rk\u{00E7}e", "T\u{00FC}rk\u{00E7}e"),
    AppLanguage("uk", "Ukrainian", "Ukrainian"),
    AppLanguage("zh-Hans", "Chinese", "Chinese"),
    AppLanguage("th", "Thai", "Thai"),
    AppLanguage("ar", "Arabic", "Arabic", isRTL: true),
]

let supportedSpeechLanguages: [AppLanguage] = supportedAppLanguages

// MARK: - ViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedTheme: String = "System"
    @Published var selectedLanguage: String = "System"
    @Published var selectedSpeechLanguage: String = "English"
    @Published var selectedModel: String = "TABAI"
    @Published var selectedVoice: String = "Iris"
    @Published var isRefreshing: Bool = false
    @Published var lastRefreshError: String?

    let themes = ["System", "Light", "Dark"]
    @Published var models: [String] = ["TABAI"]
    let voices = ["Iris", "Nova", "Orion"]

    var appLanguages: [AppLanguage] { supportedAppLanguages }
    var speechLanguages: [AppLanguage] { supportedSpeechLanguages }

    private var settingsService: SettingsServiceProtocol

    init(settingsService: SettingsServiceProtocol) {
        self.settingsService = settingsService
        // Load speech language from local
        self.selectedSpeechLanguage = UserDefaults.standard.string(forKey: "tai.speechLanguage") ?? "English"
    }

    func configure(settingsService: SettingsServiceProtocol) {
        self.settingsService = settingsService
    }

    func updateModels(_ models: [ModelCatalog.Model]) {
        let names = models.compactMap { model in
            if let displayName = model.displayName, displayName.isEmpty == false {
                return displayName
            }
            return model.id
        }
        if names.isEmpty == false {
            self.models = names
            if models.contains(where: { $0.displayName == selectedModel }) == false {
                selectedModel = names.first ?? selectedModel
            }
        }
    }

    func refresh() async {
        isRefreshing = true
        lastRefreshError = nil
        defer { isRefreshing = false }

        do {
            let settings = try await settingsService.fetchSettings()
            selectedTheme = Self.themeLabel(for: settings.theme)
            selectedLanguage = Self.languageLabel(for: settings.language)
            selectedModel = settings.model
            selectedVoice = UserDefaults.standard.string(forKey: "tai.voicePreference") ?? settings.voice
        } catch {
            lastRefreshError = "Could not load settings. Pull to refresh."
        }
    }

    func selectTheme(_ theme: String) {
        selectedTheme = theme
        persistSettings()
    }

    func selectLanguage(_ language: String) {
        selectedLanguage = language
        persistSettings()
    }

    func selectSpeechLanguage(_ language: AppLanguage) {
        selectedSpeechLanguage = language.label
        UserDefaults.standard.set(language.id, forKey: "tai.speechLanguage")
        UserDefaults.standard.set(language.label, forKey: "tai.speechLanguageLabel")
    }

    func selectModel(_ model: String) {
        selectedModel = model
        persistSettings()
    }

    func selectVoice(_ voice: String) {
        selectedVoice = voice
        persistSettings()
    }

    private func persistSettings() {
        UserDefaults.standard.set(Self.themeCode(for: selectedTheme), forKey: "tai.themePreference")
        UserDefaults.standard.set(Self.languageCode(for: selectedLanguage), forKey: "tai.languagePreference")
        UserDefaults.standard.set(selectedVoice, forKey: "tai.voicePreference")
        let snapshot = AppSettings(
            theme: Self.themeCode(for: selectedTheme),
            language: Self.languageCode(for: selectedLanguage),
            model: selectedModel,
            voice: selectedVoice
        )
        Task {
            try? await settingsService.updateSettings(snapshot)
        }
    }

    private static func themeLabel(for code: String) -> String {
        switch code.lowercased() {
        case "light": return "Light"
        case "dark": return "Dark"
        default: return "System"
        }
    }

    private static func themeCode(for label: String) -> String {
        switch label.lowercased() {
        case "light": return "light"
        case "dark": return "dark"
        default: return "system"
        }
    }

    static func languageLabel(for code: String) -> String {
        supportedAppLanguages.first(where: { $0.id == code })?.label ?? "System"
    }

    static func languageCode(for label: String) -> String {
        supportedAppLanguages.first(where: { $0.label == label })?.id ?? "system"
    }
}
