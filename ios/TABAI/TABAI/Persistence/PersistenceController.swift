import Foundation
import Combine

@MainActor
final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    private static let threadsKey = "tai.cache.threads"
    private static let messagesKey = "tai.cache.messages"

    @Published private(set) var threads: [ChatThreadRecord] = []
    @Published private(set) var messages: [ChatMessageRecord] = []

    private init() {
        let decoder = JSONDecoder()
        if let threadData = UserDefaults.standard.data(forKey: Self.threadsKey),
           let decodedThreads = try? decoder.decode([ChatThreadRecord].self, from: threadData) {
            threads = decodedThreads
        } else {
            threads = []
        }
        if let messageData = UserDefaults.standard.data(forKey: Self.messagesKey),
           let decodedMessages = try? decoder.decode([ChatMessageRecord].self, from: messageData) {
            messages = decodedMessages
        } else {
            messages = []
        }
    }

    func reset() {
        threads = []
        messages = []
        persist()
    }

    func upsertThreads(_ summaries: [ChatThreadSummary]) {
        for summary in summaries {
            if let index = threads.firstIndex(where: { $0.remoteId == summary.remoteId }) {
                let existing = threads[index]
                if summary.updatedAt >= existing.updatedAt {
                    threads[index] = ChatThreadRecord(
                        id: existing.id,
                        remoteId: summary.remoteId,
                        title: summary.title,
                        lastMessage: summary.lastMessage,
                        createdAt: summary.createdAt,
                        updatedAt: summary.updatedAt,
                        isPinned: summary.isPinned,
                        modelId: summary.modelId,
                        modelDisplayName: summary.modelDisplayName,
                        folderId: summary.folderId
                    )
                }
            } else {
                threads.append(ChatThreadRecord(
                    id: UUID(),
                    remoteId: summary.remoteId,
                    title: summary.title,
                    lastMessage: summary.lastMessage,
                    createdAt: summary.createdAt,
                    updatedAt: summary.updatedAt,
                    isPinned: summary.isPinned,
                    modelId: summary.modelId,
                    modelDisplayName: summary.modelDisplayName,
                    folderId: summary.folderId
                ))
            }
        }
        persist()
    }

    func updateLocalThread(remoteId: String, title: String? = nil, isPinned: Bool? = nil) {
        guard let index = threads.firstIndex(where: { $0.remoteId == remoteId }) else { return }
        var record = threads[index]
        if let title {
            record.title = title
        }
        if let isPinned {
            record.isPinned = isPinned
        }
        record.updatedAt = max(record.updatedAt, Date())
        threads[index] = record
        persist()
    }

    func updateLocalThreadFolder(remoteId: String, folderId: String?) {
        guard let index = threads.firstIndex(where: { $0.remoteId == remoteId }) else { return }
        var record = threads[index]
        record.folderId = folderId
        record.updatedAt = max(record.updatedAt, Date())
        threads[index] = record
        persist()
    }

    func deleteThread(remoteId: String) {
        threads.removeAll { $0.remoteId == remoteId }
        messages.removeAll { $0.threadRemoteId == remoteId }
        persist()
    }

    func upsertMessages(_ summaries: [ChatMessageSummary], threadRemoteId: String) {
        for summary in summaries {
            if let index = messages.firstIndex(where: { $0.remoteId == summary.remoteId }) {
                let existing = messages[index]
                if summary.updatedAt >= existing.updatedAt {
                    messages[index] = ChatMessageRecord(
                        id: existing.id,
                        remoteId: summary.remoteId,
                        threadRemoteId: threadRemoteId,
                        role: summary.role,
                        text: summary.text,
                        createdAt: summary.createdAt,
                        updatedAt: summary.updatedAt
                    )
                }
            } else {
                messages.append(ChatMessageRecord(
                    id: UUID(),
                    remoteId: summary.remoteId,
                    threadRemoteId: threadRemoteId,
                    role: summary.role,
                    text: summary.text,
                    createdAt: summary.createdAt,
                    updatedAt: summary.updatedAt
                ))
            }
        }
        persist()
    }

    func messages(for threadRemoteId: String) -> [ChatMessageRecord] {
        messages.filter { $0.threadRemoteId == threadRemoteId }
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let threadData = try? encoder.encode(threads) {
            UserDefaults.standard.set(threadData, forKey: Self.threadsKey)
        }
        if let messageData = try? encoder.encode(messages) {
            UserDefaults.standard.set(messageData, forKey: Self.messagesKey)
        }
    }
}
