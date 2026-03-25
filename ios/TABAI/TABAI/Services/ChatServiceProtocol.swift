import Foundation

struct ChatThreadSummary: Equatable {
    let remoteId: String
    let title: String
    let lastMessage: String
    let createdAt: Date
    let updatedAt: Date
    let isPinned: Bool
    let modelId: String?
    let modelDisplayName: String?
    let folderId: String?
}

struct ChatMessageSummary: Equatable {
    let remoteId: String
    let role: String
    let text: String
    let createdAt: Date
    let updatedAt: Date
}

struct ChatDetail: Equatable {
    let thread: ChatThreadSummary
    let messages: [ChatMessageSummary]
}

struct ChatFolderSummary: Equatable, Identifiable {
    let id: String
    let name: String
    let color: String?
}

protocol ChatServiceProtocol {
    func fetchChats() async throws -> [ChatThreadSummary]
    func fetchChatDetail(id: String) async throws -> ChatDetail
    func createChat(id: String, title: String, modelId: String?, folderId: String?) async throws -> ChatDetail
    func createMessage(chatId: String, role: String, text: String) async throws -> ChatMessageSummary
    func updateChat(id: String, title: String?, folderId: String?, isPinned: Bool?) async throws
    func renameChat(id: String, title: String) async throws
    func deleteChat(id: String) async throws
    func fetchFolders() async throws -> [ChatFolderSummary]
    func createFolder(name: String) async throws -> ChatFolderSummary
    func deleteFolder(id: String) async throws
    func completeChat(model: String, messages: [ChatMessageSummary]) async throws -> String
    /// Streams chat response from model. Returns the messageId of the created assistant message on backend.
    func streamChat(chatId: String, model: String, messages: [ChatMessageSummary], onToken: @escaping (String) -> Void, onMetadata: ((String) -> Void)?) async throws -> String?
}
