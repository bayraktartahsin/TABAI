import Foundation

// MARK: - Generation Types

enum GenerationType: String, Codable {
    case image
    case video
    case imageToVideo = "image_to_video"
}

enum GenerationStatusValue: String, Codable {
    case queued
    case processing
    case completed
    case failed
    case cancelled
}

// MARK: - fal.ai Model Catalog

struct FalModel: Identifiable {
    let id: String          // fal.ai model ID
    let displayName: String
    let generationType: GenerationType
    let minTier: PlanTier
    let costDescription: String
    let speed: String

    static let imageModels: [FalModel] = [
        FalModel(id: "fal-ai/flux/schnell", displayName: "TABAI Image Fast", generationType: .image, minTier: .starter, costDescription: "~$0.003", speed: "~2s"),
        FalModel(id: "fal-ai/flux/dev", displayName: "TABAI Image", generationType: .image, minTier: .pro, costDescription: "~$0.025", speed: "~5s"),
        FalModel(id: "fal-ai/flux-2-pro", displayName: "TABAI Image Pro", generationType: .image, minTier: .pro, costDescription: "~$0.03", speed: "~8s"),
        FalModel(id: "fal-ai/flux-2-pro-ultra", displayName: "TABAI Image Ultra", generationType: .image, minTier: .power, costDescription: "~$0.07", speed: "~12s"),
    ]

    static let videoModels: [FalModel] = [
        FalModel(id: "fal-ai/kling-video/v2.5/master/text-to-video", displayName: "TABAI Video", generationType: .video, minTier: .pro, costDescription: "~$1.12", speed: "~60s"),
        FalModel(id: "fal-ai/veo3", displayName: "TABAI Video Pro", generationType: .video, minTier: .power, costDescription: "~$1.00", speed: "~90s"),
        FalModel(id: "fal-ai/sora-2-pro", displayName: "TABAI Video Ultra", generationType: .video, minTier: .power, costDescription: "~$2.50", speed: "~120s"),
    ]

    static let imageToVideoModels: [FalModel] = [
        FalModel(id: "fal-ai/kling-video/v2.5/master/image-to-video", displayName: "Animate Photo", generationType: .imageToVideo, minTier: .pro, costDescription: "~$1.12", speed: "~60s"),
    ]

    static func accessibleModels(for tier: PlanTier, type: GenerationType) -> [FalModel] {
        let tierOrder: [PlanTier: Int] = [.free: 0, .starter: 1, .pro: 2, .power: 3]
        let userLevel = tierOrder[tier] ?? 0
        let source: [FalModel]
        switch type {
        case .image: source = imageModels
        case .video: source = videoModels
        case .imageToVideo: source = imageToVideoModels
        }
        return source.filter { (tierOrder[$0.minTier] ?? 0) <= userLevel }
    }
}

// MARK: - Request / Response DTOs

struct GenerationSubmitRequest: Encodable {
    let prompt: String
    let negativePrompt: String?
    let modelId: String
    let chatId: String?
    // Image-specific
    let imageSize: String?
    let numImages: Int?
    let style: String?
    // Video-specific
    let duration: String?
    let resolution: String?
    let imageUrl: String?
}

struct GenerationSubmitResponse: Decodable {
    let id: String
    let falRequestId: String
    let status: String
}

struct GenerationStatusResponse: Decodable {
    let id: String
    let status: String
    let resultUrl: String?
    let metadata: AnyCodable?
    let queuePosition: Int?
    let errorMessage: String?
}

struct GenerationRecord: Decodable, Identifiable {
    let id: String
    let userId: String
    let chatId: String?
    let falRequestId: String
    let provider: String
    let modelId: String
    let modelDisplayName: String?
    let generationType: String
    let status: String
    let prompt: String
    let negativePrompt: String?
    let parameters: AnyCodable?
    let resultUrl: String?
    let resultMetadata: AnyCodable?
    let estimatedCostUnits: Int
    let actualCostUnits: Int?
    let errorMessage: String?
    let createdAt: String
    let completedAt: String?

    var statusValue: GenerationStatusValue {
        GenerationStatusValue(rawValue: status) ?? .queued
    }

    var genType: GenerationType {
        GenerationType(rawValue: generationType) ?? .image
    }
}

struct GenerationHistoryResponse: Decodable {
    let generations: [GenerationRecord]
}

// MARK: - AnyCodable helper

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let number = try? container.decode(Double.self) {
            value = number
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let string = value as? String {
            try container.encode(string)
        } else if let number = value as? Double {
            try container.encode(number)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else {
            try container.encodeNil()
        }
    }
}
