import Foundation

struct MockChatService: ChatServiceProtocol {
    func fetchChats() async throws -> [ChatThreadSummary] {
        [
            ChatThreadSummary(remoteId: UUID().uuidString, title: "Project update", lastMessage: "Drafted a 4-bullet update.", createdAt: .now.addingTimeInterval(-3600), updatedAt: .now, isPinned: true, modelId: "mock-gpt", modelDisplayName: "GPT Mock", folderId: nil),
            ChatThreadSummary(remoteId: UUID().uuidString, title: "Travel ideas", lastMessage: "3-day Istanbul itinerary.", createdAt: .now.addingTimeInterval(-7200), updatedAt: .now.addingTimeInterval(-1800), isPinned: false, modelId: "mock-gemini", modelDisplayName: "Gemini Mock", folderId: "folder-1"),
            ChatThreadSummary(remoteId: UUID().uuidString, title: "Swift async", lastMessage: "Explained async/await basics.", createdAt: .now.addingTimeInterval(-10800), updatedAt: .now.addingTimeInterval(-3600), isPinned: false, modelId: "mock-claude", modelDisplayName: "Claude Mock", folderId: nil)
        ]
    }

    func fetchChatDetail(id: String) async throws -> ChatDetail {
        let thread = ChatThreadSummary(remoteId: id, title: "Project update", lastMessage: "Drafted a 4-bullet update.", createdAt: .now.addingTimeInterval(-3600), updatedAt: .now, isPinned: false, modelId: "mock-gpt", modelDisplayName: "GPT Mock", folderId: nil)
        let messages = [
            ChatMessageSummary(remoteId: UUID().uuidString, role: "user", text: "Status update?", createdAt: .now.addingTimeInterval(-3500), updatedAt: .now.addingTimeInterval(-3500)),
            ChatMessageSummary(remoteId: UUID().uuidString, role: "assistant", text: "Drafted a 4-bullet update.", createdAt: .now.addingTimeInterval(-3400), updatedAt: .now.addingTimeInterval(-3400))
        ]
        return ChatDetail(thread: thread, messages: messages)
    }

    func createChat(id: String, title: String, modelId: String?, folderId: String?) async throws -> ChatDetail {
        let thread = ChatThreadSummary(remoteId: id, title: title, lastMessage: "", createdAt: .now, updatedAt: .now, isPinned: false, modelId: modelId, modelDisplayName: modelId, folderId: folderId)
        return ChatDetail(thread: thread, messages: [])
    }

    func createMessage(chatId: String, role: String, text: String) async throws -> ChatMessageSummary {
        ChatMessageSummary(remoteId: UUID().uuidString, role: role.lowercased(), text: text, createdAt: .now, updatedAt: .now)
    }

    func updateChat(id: String, title: String?, folderId: String?, isPinned: Bool?) async throws {}

    func renameChat(id: String, title: String) async throws {}

    func deleteChat(id: String) async throws {}

    func fetchFolders() async throws -> [ChatFolderSummary] {
        [
            ChatFolderSummary(id: "folder-1", name: "Projects", color: nil),
            ChatFolderSummary(id: "folder-2", name: "Research", color: nil)
        ]
    }

    func createFolder(name: String) async throws -> ChatFolderSummary {
        ChatFolderSummary(id: UUID().uuidString, name: name, color: nil)
    }

    func deleteFolder(id: String) async throws {}

    func completeChat(model: String, messages: [ChatMessageSummary]) async throws -> String {
        "This is a mock response."
    }

    func streamChat(chatId: String, model: String, messages: [ChatMessageSummary], onToken: @escaping (String) -> Void, onMetadata: ((String) -> Void)? = nil) async throws -> String? {
        let words = ["Streaming", "mock", "response", "from", "local", "service."]
        for word in words {
            try? await Task.sleep(nanoseconds: 120_000_000)
            onToken("\(word) ")
        }
        return UUID().uuidString  // Return mock message ID
    }
}
