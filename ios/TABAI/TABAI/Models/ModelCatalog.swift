import Foundation

struct ModelCatalog: Codable {
    struct Model: Codable, Identifiable {
        private enum CodingKeys: String, CodingKey {
            case id
            case displayName
            case providerModelId
            case providerName
            case providerSlug
            case logoURL
            case vendor
            case capabilities
            case verified
            case verificationStatus
            case contextLength
            case pricingTier
            case requiredPlanTier
            case canAccess
            case lockReason
        }

        let id: String
        let displayName: String?
        let providerModelId: String?
        let providerName: String?
        let providerSlug: String?
        let logoURL: String?
        let vendor: String?
        let capabilities: [String]
        let verified: Bool
        let verificationStatus: String?
        let contextLength: Int?
        let pricingTier: String?
        let requiredPlanTier: PlanTier
        let canAccess: Bool
        let lockReason: String?

        init(
            id: String,
            displayName: String?,
            providerModelId: String?,
            providerName: String?,
            providerSlug: String?,
            logoURL: String?,
            vendor: String?,
            capabilities: [String],
            verified: Bool,
            verificationStatus: String?,
            contextLength: Int?,
            pricingTier: String?,
            requiredPlanTier: PlanTier,
            canAccess: Bool,
            lockReason: String?
        ) {
            self.id = id
            self.displayName = displayName
            self.providerModelId = providerModelId
            self.providerName = providerName
            self.providerSlug = providerSlug
            self.logoURL = logoURL
            self.vendor = vendor
            self.capabilities = capabilities
            self.verified = verified
            self.verificationStatus = verificationStatus
            self.contextLength = contextLength
            self.pricingTier = pricingTier
            self.requiredPlanTier = requiredPlanTier
            self.canAccess = canAccess
            self.lockReason = lockReason
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            providerModelId = try container.decodeIfPresent(String.self, forKey: .providerModelId)
            providerName = try container.decodeIfPresent(String.self, forKey: .providerName)
            providerSlug = try container.decodeIfPresent(String.self, forKey: .providerSlug)
            logoURL = try container.decodeIfPresent(String.self, forKey: .logoURL)
            vendor = try container.decodeIfPresent(String.self, forKey: .vendor)
            capabilities = try container.decodeIfPresent([String].self, forKey: .capabilities) ?? []
            verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
            verificationStatus = try container.decodeIfPresent(String.self, forKey: .verificationStatus)
            contextLength = try container.decodeIfPresent(Int.self, forKey: .contextLength)
            pricingTier = try container.decodeIfPresent(String.self, forKey: .pricingTier)
            requiredPlanTier = try container.decodeIfPresent(PlanTier.self, forKey: .requiredPlanTier) ?? .free
            canAccess = try container.decodeIfPresent(Bool.self, forKey: .canAccess) ?? true
            lockReason = try container.decodeIfPresent(String.self, forKey: .lockReason)
        }
    }

    let models: [Model]

    static func load() -> ModelCatalog? {
        guard let url = Bundle.main.url(forResource: "ModelCatalog", withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(ModelCatalog.self, from: data)
    }
}
