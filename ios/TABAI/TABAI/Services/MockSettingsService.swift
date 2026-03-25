import Foundation

struct MockSettingsService: SettingsServiceProtocol {
    func fetchProfile() async throws -> UserProfile {
        UserProfile(email: "demo@tai.app", planTier: .free, entitlement: nil)
    }

    func fetchSettings() async throws -> AppSettings {
        AppSettings(theme: "system", language: "system", model: "TAI-1", voice: "Iris")
    }

    func updateSettings(_ settings: AppSettings) async throws {
    }

    func updateAccount(currentPassword: String, email: String?, password: String?) async throws -> UserProfile {
        UserProfile(email: email ?? "demo@tai.app", planTier: .free, entitlement: nil)
    }
}
