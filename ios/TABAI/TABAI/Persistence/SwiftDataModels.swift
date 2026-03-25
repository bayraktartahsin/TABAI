import Foundation

struct ChatThreadRecord: Identifiable, Equatable, Codable {
    let id: UUID
    let remoteId: String
    var title: String
    var lastMessage: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var modelId: String?
    var modelDisplayName: String?
    var folderId: String?
}

struct ChatMessageRecord: Identifiable, Equatable, Codable {
    let id: UUID
    let remoteId: String
    let threadRemoteId: String
    let role: String
    let text: String
    let createdAt: Date
    let updatedAt: Date
}
