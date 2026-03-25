import Foundation

struct TABAIBootstrapPayload {
    let user: UserProfile
    let settings: AppSettings
    let models: [ModelCatalog.Model]
    let chats: [ChatThreadSummary]
}

struct TABAIBootstrapService {
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
        if let string = value as? String {
            if let date = iso8601.date(from: string) {
                return date
            }
            return ISO8601DateFormatter().date(from: string)
        }
        if let interval = value as? TimeInterval {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
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

    func fetchBootstrap() async throws -> TABAIBootstrapPayload {
        let url = client.baseURL.appendingPathComponent("api/bootstrap")
        let (data, response) = try await client.requestRaw(method: "GET", url: url)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let user = json["user"] as? [String: Any],
            let email = user["email"] as? String,
            let chats = json["chats"] as? [[String: Any]],
            let models = json["models"] as? [[String: Any]]
        else {
            throw Error.invalidResponse
        }

        let settingsJson = json["settings"] as? [String: Any]
        let settings = AppSettings(
            theme: (settingsJson?["theme"] as? String) ?? "system",
            language: (settingsJson?["language"] as? String) ?? "system",
            model: "TAI-1",
            voice: "Iris"
        )

        return TABAIBootstrapPayload(
            user: UserProfile(
                email: email,
                planTier: parsePlanTier(user["planTier"]),
                entitlement: parseEntitlement(user["entitlement"])
            ),
            settings: settings,
            models: models.compactMap(mapModel(from:)),
            chats: chats.compactMap(mapThread(from:))
        )
    }

    private func mapModel(from dict: [String: Any]) -> ModelCatalog.Model? {
        guard let id = dict["id"] as? String else { return nil }
        let provider = dict["provider"] as? [String: Any]
        let rawLogoURL = dict["logoUrl"] as? String
        return ModelCatalog.Model(
            id: id,
            displayName: (dict["displayName"] as? String) ?? (dict["name"] as? String) ?? id,
            providerModelId: dict["providerModelId"] as? String,
            providerName: provider?["name"] as? String,
            providerSlug: provider?["slug"] as? String,
            logoURL: resolveLogoURL(rawLogoURL),
            vendor: dict["vendor"] as? String,
            capabilities: dict["capabilities"] as? [String] ?? [],
            verified: dict["verified"] as? Bool ?? false,
            verificationStatus: dict["verificationStatus"] as? String,
            contextLength: dict["contextLength"] as? Int,
            pricingTier: dict["pricingTier"] as? String,
            requiredPlanTier: PlanTier(rawValue: ((dict["requiredPlanTier"] as? String) ?? "free").lowercased()) ?? .free,
            canAccess: dict["canAccess"] as? Bool ?? true,
            lockReason: dict["lockReason"] as? String
        )
    }

    private func mapThread(from item: [String: Any]) -> ChatThreadSummary? {
        guard let id = item["id"] as? String else { return nil }
        let title = (item["title"] as? String) ?? "New Chat"
        let updatedAt = parseDate(item["updatedAt"]) ?? Date()
        let createdAt = parseDate(item["createdAt"]) ?? updatedAt
        let lastMessage = ((item["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        let model = item["model"] as? [String: Any]
        return ChatThreadSummary(
            remoteId: id,
            title: title,
            lastMessage: lastMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isPinned: (item["isPinned"] as? Bool) ?? false,
            modelId: item["modelId"] as? String,
            modelDisplayName: (model?["displayName"] as? String) ?? (model?["name"] as? String),
            folderId: item["folderId"] as? String
        )
    }

    private func resolveLogoURL(_ value: String?) -> String? {
        guard let value, value.isEmpty == false else { return nil }
        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            return value
        }
        return client.baseURL.appendingPathComponent(value.replacingOccurrences(of: "^/+", with: "", options: .regularExpression)).absoluteString
    }
}
