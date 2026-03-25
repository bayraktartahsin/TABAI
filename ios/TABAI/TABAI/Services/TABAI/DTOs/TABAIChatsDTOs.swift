import Foundation

struct TABAIChatsEnvelope: Codable {
    let data: [TABAIChatItem]
}

struct TABAIChatItem: Codable {
    let id: String
    let title: String?
    let updatedAt: Double?
    let createdAt: Double?
    let chat: TABAIChatPayloadContainer?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case updatedAt = "updated_at"
        case createdAt = "created_at"
        case chat
    }
}

struct TABAIChatDetail: Codable {
    let id: String
    let title: String?
    let updatedAt: Double?
    let createdAt: Double?
    let chat: TABAIChatPayloadContainer?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case updatedAt = "updated_at"
        case createdAt = "created_at"
        case chat
    }
}

struct TABAIChatPayloadContainer: Codable {
    let payload: TABAIChatPayload?

    init(from decoder: Decoder) throws {
        if let payload = try? TABAIChatPayload(from: decoder) {
            self.payload = payload
            return
        }
        if let string = try? String(from: decoder) {
            if let data = string.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(TABAIChatPayload.self, from: data) {
                self.payload = decoded
                return
            }
        }
        self.payload = nil
    }
}

struct TABAIChatPayload: Codable {
    let messages: [TABAIMessage]?
}

struct TABAIMessage: Codable {
    let id: String?
    let role: String
    let content: String
    let createdAt: Double?
    let updatedAt: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
