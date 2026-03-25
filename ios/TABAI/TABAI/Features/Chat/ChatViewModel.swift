import Foundation
import Combine
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    enum StreamingPhase: Equatable {
        case thinking
        case generating
        case finishing
        case idle
    }

    struct ChatMessage: Identifiable, Equatable {
        enum Role {
            case user
            case assistant
        }

        let id: UUID
        let role: Role
        var text: String
        var isStreaming: Bool
        var isFailed: Bool
        var remoteId: String?  // Track server ID for persistent sync
        var poweredBy: String? // TABAI composite model: actual model used
    }

    enum AttachmentKind: String {
        case photo
        case camera
        case file

        var title: String {
            switch self {
            case .photo:
                return "Photo"
            case .camera:
                return "Camera"
            case .file:
                return "File"
            }
        }
    }

    struct Attachment: Identifiable, Equatable {
        let id: UUID
        let kind: AttachmentKind
        let name: String
    }

    // Attachment validation constants (must match backend and web limits)
    private static let MAX_ATTACHMENTS = 6
    private static let SUPPORTED_TYPES: Set<AttachmentKind> = [.photo]
    
    struct AttachmentValidationError: Error {
        let message: String
    }

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isStreaming: Bool = false
    @Published private(set) var streamingPhase: StreamingPhase = .idle
    @Published private(set) var streamRenderTick: Int = 0
    @Published private(set) var stopPulseTrigger: Int = 0
    @Published var pendingAttachments: [Attachment] = []
    @Published private(set) var isLoadingChat: Bool = false
    @Published private(set) var latestError: String?

    private var chatService: ChatServiceProtocol
    private let persistence: PersistenceController
    private let usageQuotaManager: UsageQuotaManager
    private var planTierProvider: () -> PlanTier = { .free }
    private var onQuotaExceeded: () -> Void = {}
    private var streamingTask: Task<Void, Never>?
    private var currentThreadId: String?
    private let modelIdProvider: () -> String?
    private let isAuthenticatedProvider: () -> Bool

    private final class StreamDeltaBuffer {
        private let lock = NSLock()
        private var pending: String = ""
        private var sawAnyToken: Bool = false

        func append(_ delta: String) {
            guard delta.isEmpty == false else { return }
            lock.lock()
            pending += delta
            sawAnyToken = true
            lock.unlock()
        }

        func drain() -> (text: String, sawToken: Bool) {
            lock.lock()
            let text = pending
            let sawToken = sawAnyToken
            pending = ""
            lock.unlock()
            return (text, sawToken)
        }
    }

    init(
        chatService: ChatServiceProtocol,
        modelIdProvider: @escaping () -> String?,
        isAuthenticatedProvider: @escaping () -> Bool = { true },
        persistence: PersistenceController? = nil,
        usageQuotaManager: UsageQuotaManager = .shared
    ) {
        self.chatService = chatService
        self.modelIdProvider = modelIdProvider
        self.isAuthenticatedProvider = isAuthenticatedProvider
        self.persistence = persistence ?? PersistenceController.shared
        self.usageQuotaManager = usageQuotaManager
    }

    func configureUsageQuota(planTierProvider: @escaping () -> PlanTier, onQuotaExceeded: @escaping () -> Void) {
        self.planTierProvider = planTierProvider
        self.onQuotaExceeded = onQuotaExceeded
    }

    func updateChatService(_ service: ChatServiceProtocol) {
        self.chatService = service
    }

    func loadChat(threadId: String) async {
        guard isAuthenticatedProvider(), threadId.isEmpty == false else { return }
        currentThreadId = threadId
        isLoadingChat = true
        latestError = nil
        do {
            let detail = try await chatService.fetchChatDetail(id: threadId)
            persistence.upsertThreads([detail.thread])
            persistence.upsertMessages(detail.messages, threadRemoteId: detail.thread.remoteId)
            applyMessages(detail.messages)
        } catch {
            latestError = "Could not load this chat. Pull to retry or open it again."
        }
        isLoadingChat = false
    }

    func beginNewChatForModelSwitch() {
        stopStreaming()
        currentThreadId = nil
        latestError = nil
        withAnimation(DS.Motion.spring) {
            messages = []
        }
    }

    func beginNewChat() {
        beginNewChatForModelSwitch()
    }

    func send(text: String) {
        Task {
            await sendAsync(text: text)
        }
    }

    func sendAsync(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !pendingAttachments.isEmpty else { return }
        guard isAuthenticatedProvider() else { return }
        guard let modelId = modelIdProvider(), modelId.isEmpty == false else { return }
        guard ensureQuotaAvailable() else { return }
        latestError = nil

        // Validate attachments BEFORE sending - fail hard if validation fails
        do {
            try validateAttachments()
        } catch let error as AttachmentValidationError {
            latestError = error.message
            return  // ← Exit without sending message if attachments invalid
        } catch {
            latestError = "Attachment validation failed. Please try again."
            return
        }
        
        // All attachments validated; include summary in message
        let attachmentSummary = pendingAttachments.map { $0.name }.joined(separator: ", ")
        let payloadText = attachmentSummary.isEmpty ? trimmed : "\(trimmed)\n\nAttachments: \(attachmentSummary)"

        withAnimation(DS.Motion.quickSpring) {
            messages.append(ChatMessage(id: UUID(), role: .user, text: payloadText, isStreaming: false, isFailed: false, remoteId: nil))
        }
        pendingAttachments.removeAll()

        // Build history using actual server IDs for sync integrity
        let history = messages.map { message in
            let actualRemoteId = message.remoteId ?? UUID().uuidString
            return ChatMessageSummary(
                remoteId: actualRemoteId,
                role: message.role == .user ? "user" : "assistant",
                text: message.text,
                createdAt: Date(),
                updatedAt: Date()
            )
        }

        do {
            if currentThreadId == nil {
                let title = String(payloadText.prefix(42))
                let detail = try await chatService.createChat(
                    id: UUID().uuidString,
                    title: title.isEmpty ? "New Chat" : title,
                    modelId: modelId,
                    folderId: nil
                )
                currentThreadId = detail.thread.remoteId
                persistence.upsertThreads([detail.thread])
            }
            guard let currentThreadId else { return }
            let created = try await chatService.createMessage(chatId: currentThreadId, role: "user", text: payloadText)
            persistence.upsertMessages([created], threadRemoteId: currentThreadId)
            // Update local message with remote ID to maintain sync
            if let lastIndex = messages.lastIndex(where: { $0.role == .user && $0.remoteId == nil }) {
                messages[lastIndex].remoteId = created.remoteId
            }
            startStreaming(chatId: currentThreadId, model: modelId, messages: history)
        } catch {
            if let lastIndex = messages.lastIndex(where: { $0.role == .user }) {
                messages[lastIndex].isFailed = true
            }
            latestError = "Message failed to send. Check connection and retry."
        }
    }

    func regenerateLastAssistant() {
        guard let lastAssistantIndex = messages.lastIndex(where: { $0.role == .assistant }) else { return }
        guard isAuthenticatedProvider() else { return }
        guard let modelId = modelIdProvider(), modelId.isEmpty == false else { return }
        guard ensureQuotaAvailable() else { return }

        // Keep existing assistant message visible locally. Without server-side message replace,
        // removing it only in-memory causes history mismatch after reload.
        let history = messages.enumerated().compactMap { entry -> ChatMessageSummary? in
            let (index, message) = entry
            guard index != lastAssistantIndex else { return nil }
            // Use actual server ID if available, fallback to new ID for unsync'd messages
            let actualRemoteId = message.remoteId ?? UUID().uuidString
            return ChatMessageSummary(
                remoteId: actualRemoteId,
                role: message.role == .user ? "user" : "assistant",
                text: message.text,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        guard let currentThreadId else { return }
        startStreaming(chatId: currentThreadId, model: modelId, messages: history)
    }

    func retryLastFailed() {
        guard let failedMessageIndex = messages.lastIndex(where: { $0.role == .assistant && $0.isFailed }) else { return }
        guard isAuthenticatedProvider() else { return }
        guard let modelId = modelIdProvider(), modelId.isEmpty == false else { return }
        guard ensureQuotaAvailable() else { return }
        
        // Preserve failed message - reset its state instead of deleting
        let failedMessageId = messages[failedMessageIndex].id
        messages[failedMessageIndex].isFailed = false
        messages[failedMessageIndex].isStreaming = true
        messages[failedMessageIndex].text = ""  // Clear any partial content
        
        // Build history of all messages except the one being retried (to avoid duplicates in history)
        let history = messages.enumerated().compactMap { entry -> ChatMessageSummary? in
            let (index, message) = entry
            guard index != failedMessageIndex else { return nil }
            // Preserve actual server IDs to maintain sync integrity
            let actualRemoteId = message.remoteId ?? UUID().uuidString
            return ChatMessageSummary(
                remoteId: actualRemoteId,
                role: message.role == .user ? "user" : "assistant",
                text: message.text,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        guard let currentThreadId else { return }
        
        isStreaming = true
        streamingPhase = .thinking
        latestError = nil
        
        stopStreaming()
        streamingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let streamedMessageId = try await self.streamWithRetryOnce(chatId: currentThreadId, model: modelId, messages: history, messageID: failedMessageId)
                if let index = self.messages.firstIndex(where: { $0.id == failedMessageId }) {
                    self.messages[index].isStreaming = false
                    // Update local message with remote ID from backend for future sync
                    if let remoteId = streamedMessageId {
                        self.messages[index].remoteId = remoteId
                    }
                }
                self.latestError = nil
                self.streamingPhase = .idle
                self.isStreaming = false
            } catch {
                if error is CancellationError || Task.isCancelled {
                    self.isStreaming = false
                    return
                }
                if let index = self.messages.firstIndex(where: { $0.id == failedMessageId }) {
                    self.messages[index].isStreaming = false
                    self.messages[index].isFailed = true
                }
                self.isStreaming = false
                self.streamingPhase = .idle
                self.latestError = "Response stopped unexpectedly. You can retry the last answer."
            }
            self.streamingTask = nil
        }
    }

    func stopStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
        streamingPhase = .idle
        stopPulseTrigger += 1
        if let lastIndex = messages.lastIndex(where: { $0.role == .assistant }) {
            messages[lastIndex].isStreaming = false
        }
    }

    func prepareForThreadSwitchIfNeeded() {
        guard isStreaming else { return }
        stopStreaming()
        latestError = "Stopped current response to switch conversations."
    }

    func startDemoIfNeeded() {
        guard messages.isEmpty else { return }
    }

    func addMockAttachment(kind: AttachmentKind) {
        let name = "\(kind.title) \(pendingAttachments.count + 1)"
        pendingAttachments.append(Attachment(id: UUID(), kind: kind, name: name))
    }

    func removeAttachment(_ attachment: Attachment) {
        pendingAttachments.removeAll { $0.id == attachment.id }
    }

    /// Validates attachments before send. Throws if validation fails.
    private func validateAttachments() throws {
        let attachments = pendingAttachments
        
        // Check count limit
        if attachments.count > Self.MAX_ATTACHMENTS {
            throw AttachmentValidationError(
                message: "Too many attachments. Maximum \(Self.MAX_ATTACHMENTS) allowed, but you have \(attachments.count)."
            )
        }
        
        // Check for unsupported types - FAIL immediately instead of filtering
        let unsupported = attachments.filter { !Self.SUPPORTED_TYPES.contains($0.kind) }
        if !unsupported.isEmpty {
            let typeList = unsupported.map { $0.kind.title }.joined(separator: ", ")
            let names = unsupported.map { $0.name }.joined(separator: ", ")
            throw AttachmentValidationError(
                message: "\(typeList) not supported yet. Only photos can be shared. Remove: \(names)"
            )
        }
    }

    private func ensureQuotaAvailable() -> Bool {
        let planTier = planTierProvider()
        guard usageQuotaManager.canSendRequest(planTier: planTier) else {
            latestError = "Usage quota reached for your current plan. Upgrade to continue."
            onQuotaExceeded()
            return false
        }
        usageQuotaManager.consumeRequest(planTier: planTier)
        return true
    }

    private func startStreaming(chatId: String, model: String, messages: [ChatMessageSummary]) {
        guard isAuthenticatedProvider(), chatId.isEmpty == false, model.isEmpty == false, currentThreadId?.isEmpty == false else { return }
        stopStreaming()

        let messageID = UUID()
        withAnimation(DS.Motion.quickSpring) {
            self.messages.append(ChatMessage(id: messageID, role: .assistant, text: "", isStreaming: true, isFailed: false, remoteId: nil))
        }
        isStreaming = true
        streamingPhase = .thinking

        streamingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let streamedMessageId = try await self.streamWithRetryOnce(chatId: chatId, model: model, messages: messages, messageID: messageID)
                if let index = self.messages.firstIndex(where: { $0.id == messageID }) {
                    self.messages[index].isStreaming = false
                    // Update local message with remote ID from backend for future sync
                    if let remoteId = streamedMessageId {
                        self.messages[index].remoteId = remoteId
                    }
                }
                self.isStreaming = false
                self.streamingPhase = .finishing
                try? await Task.sleep(nanoseconds: 250_000_000)
                if Task.isCancelled == false {
                    self.streamingPhase = .idle
                }
                self.latestError = nil
                self.streamingTask = nil
            } catch {
                if error is CancellationError || Task.isCancelled {
                    self.isStreaming = false
                    self.streamingPhase = .idle
                    self.streamingTask = nil
                    return
                }
                if let index = self.messages.firstIndex(where: { $0.id == messageID }) {
                    self.messages[index].isStreaming = false
                    self.messages[index].isFailed = true
                }
                self.isStreaming = false
                self.streamingPhase = .idle
                self.latestError = "Response stopped unexpectedly. You can retry the last answer."
                self.streamingTask = nil
            }
        }
    }

    private func streamWithRetryOnce(chatId: String, model: String, messages: [ChatMessageSummary], messageID: UUID) async throws -> String? {
        var attempt = 0
        while true {
            let buffer = StreamDeltaBuffer()
            let flushIntervalNanoseconds: UInt64 = 75_000_000
            var streamedMessageId: String?

            func flushBufferedDeltas(final: Bool = false) {
                let drained = buffer.drain()
                if drained.sawToken && streamingPhase == .thinking {
                    streamingPhase = .generating
                }
                guard drained.text.isEmpty == false,
                      let index = self.messages.firstIndex(where: { $0.id == messageID }) else {
                    return
                }
                self.messages[index].text += drained.text
                self.streamRenderTick &+= 1
                if final {
                    self.messages[index].isStreaming = false
                }
            }

            let flushTask = Task { @MainActor in
                while Task.isCancelled == false {
                    try? await Task.sleep(nanoseconds: flushIntervalNanoseconds)
                    guard Task.isCancelled == false else { return }
                    flushBufferedDeltas()
                }
            }

            do {
                streamedMessageId = try await chatService.streamChat(chatId: chatId, model: model, messages: messages, onToken: { delta in
                    buffer.append(delta)
                }, onMetadata: { poweredBy in
                    Task { @MainActor in
                        if let index = self.messages.firstIndex(where: { $0.id == messageID }) {
                            self.messages[index].poweredBy = poweredBy
                        }
                    }
                })
                flushTask.cancel()
                flushBufferedDeltas(final: true)
                return streamedMessageId
            } catch {
                flushTask.cancel()
                flushBufferedDeltas()
                if Task.isCancelled || attempt >= 1 {
                    throw error
                }
                attempt += 1
            }
        }
    }

    private func applyMessages(_ summaries: [ChatMessageSummary]) {
        withAnimation(DS.Motion.spring) {
            // Use remoteId as deterministic local ID to maintain sync integrity
            // This ensures messages with same remoteId always get same local ID after reload
            messages = summaries.map { summary in
                let localId = UUID(uuidString: summary.remoteId.replacingOccurrences(of: "-", with: "").prefix(36).lowercased()) ?? UUID()
                return ChatMessage(
                    id: localId,
                    role: summary.role == "user" ? .user : .assistant,
                    text: summary.text,
                    isStreaming: false,
                    isFailed: false,
                    remoteId: summary.remoteId
                )
            }
        }
    }
}
