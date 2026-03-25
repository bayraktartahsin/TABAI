import Foundation

struct TABAISettingsService: SettingsServiceProtocol {
    enum Error: Swift.Error {
        case invalidResponse
    }

    let client: TABAIClient

    private let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private func parseDate(_ value: Any?) -> Date? {
        guard let raw = value as? String else { return nil }
        if let date = iso8601.date(from: raw) {
            return date
        }
        return ISO8601DateFormatter().date(from: raw)
    }

    private func parsePlanTier(_ value: Any?) -> PlanTier {
        guard let raw = value as? String else { return .free }
        return PlanTier(rawValue: raw.lowercased()) ?? .free
    }

    private func parseEntitlement(_ value: Any?) -> EntitlementInfo? {
        guard
            let dict = value as? [String: Any],
            let id = dict["id"] as? String,
            let userId = dict["userId"] as? String,
            let sourceRaw = dict["source"] as? String,
            let statusRaw = dict["status"] as? String,
            let source = EntitlementSource(rawValue: sourceRaw.lowercased()),
            let status = EntitlementStatus(rawValue: statusRaw.lowercased()),
            let startAt = parseDate(dict["startAt"]),
            let updatedAt = parseDate(dict["updatedAt"])
        else {
            return nil
        }

        return EntitlementInfo(
            id: id,
            userId: userId,
            planTier: parsePlanTier(dict["planTier"]),
            source: source,
            status: status,
            startAt: startAt,
            expiresAt: parseDate(dict["expiresAt"]),
            autoRenew: (dict["autoRenew"] as? Bool) ?? false,
            externalProductId: dict["externalProductId"] as? String,
            externalOriginalTransactionId: dict["externalOriginalTransactionId"] as? String,
            lastValidatedAt: parseDate(dict["lastValidatedAt"]),
            updatedAt: updatedAt
        )
    }

    private func parseUserProfile(_ user: [String: Any]) -> UserProfile? {
        guard let email = user["email"] as? String else { return nil }
        return UserProfile(
            email: email,
            planTier: parsePlanTier(user["planTier"]),
            entitlement: parseEntitlement(user["entitlement"])
        )
    }

    func fetchProfile() async throws -> UserProfile {
        let url = client.baseURL.appendingPathComponent("api/auth/me")
        let (data, response) = try await client.requestRaw(method: "GET", url: url)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let user = json["user"] as? [String: Any],
            let profile = parseUserProfile(user)
        else {
            throw Error.invalidResponse
        }

        return profile
    }

    func fetchSettings() async throws -> AppSettings {
        let url = client.baseURL.appendingPathComponent("api/settings")
        let (data, response) = try await client.requestRaw(method: "GET", url: url)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let settings = json["settings"] as? [String: Any]
        else {
            throw Error.invalidResponse
        }

        let theme = (settings["theme"] as? String) ?? "system"
        let language = (settings["language"] as? String) ?? "system"
        return AppSettings(theme: theme, language: language, model: "TAI-1", voice: "Iris")
    }

    func updateSettings(_ settings: AppSettings) async throws {
        let url = client.baseURL.appendingPathComponent("api/settings")
        let body = try JSONSerialization.data(withJSONObject: [
            "theme": settings.theme,
            "language": settings.language
        ])

        let (_, response) = try await client.requestRaw(method: "PATCH", url: url, body: body)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }
    }

    func updateAccount(currentPassword: String, email: String?, password: String?) async throws -> UserProfile {
        let url = client.baseURL.appendingPathComponent("api/settings/account")
        var payload: [String: Any] = ["currentPassword": currentPassword]
        if let email, email.isEmpty == false {
            payload["email"] = email
        }
        if let password, password.isEmpty == false {
            payload["password"] = password
        }
        let body = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await client.requestRaw(method: "PATCH", url: url, body: body)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let user = json["user"] as? [String: Any],
            let profile = parseUserProfile(user)
        else {
            throw Error.invalidResponse
        }
        return profile
    }
}
