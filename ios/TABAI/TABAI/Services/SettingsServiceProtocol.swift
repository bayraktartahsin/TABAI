import Foundation

enum PlanTier: String, Codable, CaseIterable {
    case free
    case starter
    case pro
    case power
}

enum EntitlementSource: String, Codable {
    case free
    case apple
    case google
    case admin
    case web
}

enum EntitlementStatus: String, Codable {
    case active
    case inactive
    case grace
    case cancelled
    case expired
}

extension EntitlementStatus {
    var grantsAccess: Bool {
        switch self {
        case .active, .grace:
            return true
        case .inactive, .cancelled, .expired:
            return false
        }
    }
}

struct EntitlementInfo: Codable, Equatable {
    let id: String
    let userId: String
    let planTier: PlanTier
    let source: EntitlementSource
    let status: EntitlementStatus
    let startAt: Date
    let expiresAt: Date?
    let autoRenew: Bool
    let externalProductId: String?
    let externalOriginalTransactionId: String?
    let lastValidatedAt: Date?
    let updatedAt: Date
}

struct UserProfile {
    let email: String
    let planTier: PlanTier
    let entitlement: EntitlementInfo?

    var effectiveEntitlement: EntitlementInfo? {
        guard let entitlement, entitlement.status.grantsAccess else { return nil }
        return entitlement
    }

    var effectivePlanTier: PlanTier {
        effectiveEntitlement?.planTier ?? planTier
    }

    func updatingEntitlement(_ entitlement: EntitlementInfo?) -> UserProfile {
        UserProfile(email: email, planTier: planTier, entitlement: entitlement)
    }
}

struct AppSettings {
    let theme: String
    let language: String
    let model: String
    let voice: String
}

protocol SettingsServiceProtocol {
    func fetchProfile() async throws -> UserProfile
    func fetchSettings() async throws -> AppSettings
    func updateSettings(_ settings: AppSettings) async throws
    func updateAccount(currentPassword: String, email: String?, password: String?) async throws -> UserProfile
}
