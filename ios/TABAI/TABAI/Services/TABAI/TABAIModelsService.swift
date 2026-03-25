import Foundation

final class TABAIModelsService: ModelsServiceProtocol {
    enum Error: Swift.Error {
        case invalidResponse
        case schemaNotRecognized
    }

    private let client: TABAIClient
    private(set) var lastEndpoint: URL?

    init(client: TABAIClient) {
        self.client = client
    }

    func updateDiscovery(_ discovery: TABAIDiscoveryResult?) {}

    func fetchModels() async throws -> [ModelCatalog.Model] {
        let endpoint = client.baseURL.appendingPathComponent("api/models")
        lastEndpoint = endpoint
        if AppConfig.enableNetworkDebugLogs {
            print("TAI models endpoint: \(endpoint.absoluteString)")
        }

        let (data, response) = try await client.requestRaw(method: "GET", url: endpoint)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }

        if let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let models = decoded["models"] as? [[String: Any]] {
            return models.compactMap { dict in
                guard let id = dict["id"] as? String else { return nil }
                let name = (dict["displayName"] as? String) ?? (dict["name"] as? String) ?? id
                let provider = dict["provider"] as? [String: Any]
                let rawLogoURL = dict["logoUrl"] as? String
                return ModelCatalog.Model(
                    id: id,
                    displayName: name,
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
        }
        throw Error.invalidResponse
    }

    private func resolveLogoURL(_ value: String?) -> String? {
        guard let value, value.isEmpty == false else { return nil }
        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            return value
        }
        return client.baseURL.appendingPathComponent(value.replacingOccurrences(of: "^/+", with: "", options: .regularExpression)).absoluteString
    }
}
