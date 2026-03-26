import Foundation
import Combine
import CryptoKit

@MainActor
final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    private static let threadsKey = "tai.cache.threads.enc"
    private static let messagesKey = "tai.cache.messages.enc"

    @Published private(set) var threads: [ChatThreadRecord] = []
    @Published private(set) var messages: [ChatMessageRecord] = []

    private init() {
        let decoder = JSONDecoder()
        if let threadData = Self.loadEncrypted(forKey: Self.threadsKey),
           let decodedThreads = try? decoder.decode([ChatThreadRecord].self, from: threadData) {
            threads = decodedThreads
        } else {
            threads = []
        }
        if let messageData = Self.loadEncrypted(forKey: Self.messagesKey),
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

    // MARK: - Encrypted persistence

    private static func encryptionKey() -> SymmetricKey {
        if let keyData = KeychainStore.load(service: "com.tabai.encryption", account: "dataKey") {
            return SymmetricKey(data: keyData)
        }
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        KeychainStore.save(data: keyData, service: "com.tabai.encryption", account: "dataKey")
        return newKey
    }

    private static func encrypt(_ data: Data) -> Data? {
        guard let sealed = try? AES.GCM.seal(data, using: encryptionKey()) else { return nil }
        return sealed.combined
    }

    private static func decrypt(_ data: Data) -> Data? {
        guard let box = try? AES.GCM.SealedBox(combined: data) else { return nil }
        return try? AES.GCM.open(box, using: encryptionKey())
    }

    private static func saveEncrypted(_ data: Data, forKey key: String) {
        if let encrypted = encrypt(data) {
            UserDefaults.standard.set(encrypted, forKey: key)
        }
    }

    private static func loadEncrypted(forKey key: String) -> Data? {
        guard let encrypted = UserDefaults.standard.data(forKey: key) else { return nil }
        return decrypt(encrypted)
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let threadData = try? encoder.encode(threads) {
            Self.saveEncrypted(threadData, forKey: Self.threadsKey)
        }
        if let messageData = try? encoder.encode(messages) {
            Self.saveEncrypted(messageData, forKey: Self.messagesKey)
        }
    }
}
