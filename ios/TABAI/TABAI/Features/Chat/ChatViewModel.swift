import Foundation
import Combine
import SwiftUI
import UIKit
import PDFKit

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
        // Generation fields
        var isGenerating: Bool = false
        var generationType: GenerationType? = nil
        var generationProgress: String? = nil
        var generationResultUrl: String? = nil
        var generationId: String? = nil
        var attachments: [Attachment] = []
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
        let imageData: Data?
        let textContent: String?
        let mimeType: String
        let fileSize: Int

        var thumbnail: UIImage? {
            guard let imageData else { return nil }
            return UIImage(data: imageData)
        }

        var dataURL: String? {
            guard let imageData else { return nil }
            return "data:\(mimeType);base64,\(imageData.base64EncodedString())"
        }

        static func == (lhs: Attachment, rhs: Attachment) -> Bool {
            lhs.id == rhs.id
        }
    }

    // Attachment validation constants (must match backend and web limits)
    private static let MAX_ATTACHMENTS = 6
    private static let MAX_IMAGE_SIZE = 8 * 1024 * 1024
    private static let MAX_TEXT_FILE_SIZE = 1 * 1024 * 1024
    private static let SUPPORTED_TYPES: Set<AttachmentKind> = [.photo, .camera, .file]

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
    @Published var showVisionRequired: Bool = false
    @Published var showLimitReached: Bool = false
    @Published var limitReachedType: LimitReachedType?
    /// Text preserved when send is blocked by vision check, so it can be re-sent.
    private(set) var visionBlockedText: String?

    private var chatService: ChatServiceProtocol
    private let persistence: PersistenceController
    private let usageQuotaManager: UsageQuotaManager
    private var planTierProvider: () -> PlanTier = { .free }
    private var onQuotaExceeded: () -> Void = {}
    private var streamingTask: Task<Void, Never>?
    private var currentThreadId: String?
    private let modelIdProvider: () -> String?
    private let isAuthenticatedProvider: () -> Bool
    private var modelCapabilitiesProvider: (String) -> [String] = { _ in [] }

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

    func configureModelCapabilities(provider: @escaping (String) -> [String]) {
        self.modelCapabilitiesProvider = provider
    }

    /// Returns true if the current model supports vision (image inputs).
    var currentModelSupportsVision: Bool {
        guard let modelId = modelIdProvider() else { return false }
        return modelCapabilitiesProvider(modelId).contains("vision")
    }

    /// Returns the display name of the current model for UI messages.
    var currentModelDisplayName: String? {
        modelIdProvider()
    }

    func updateChatService(_ service: ChatServiceProtocol) {
        self.chatService = service
    }

    /// Re-sends the message that was blocked by the vision capability check.
    func resendAfterVisionResolved() {
        guard let text = visionBlockedText else { return }
        visionBlockedText = nil
        send(text: text)
    }

    /// Removes image attachments and re-sends only text + remaining file attachments.
    func removeImagesAndResend() {
        pendingAttachments.removeAll { $0.kind == .photo || $0.kind == .camera }
        guard let text = visionBlockedText else { return }
        visionBlockedText = nil
        send(text: text)
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

        // Check vision capability for image attachments
        let hasImageAttachments = pendingAttachments.contains { $0.kind == .photo || $0.kind == .camera }
        if hasImageAttachments && !currentModelSupportsVision {
            visionBlockedText = trimmed  // preserve text for re-send
            showVisionRequired = true
            return  // ← Show sheet instead of sending
        }
        visionBlockedText = nil

        // Build API attachments from real data
        let apiAttachments: [[String: Any]] = pendingAttachments.compactMap { attachment in
            switch attachment.kind {
            case .photo, .camera:
                guard let dataURL = attachment.dataURL else { return nil }
                return [
                    "type": "image_url",
                    "name": attachment.name,
                    "mime": attachment.mimeType,
                    "size": attachment.fileSize,
                    "image_url": ["url": dataURL]
                ] as [String: Any]
            case .file:
                guard let text = attachment.textContent else { return nil }
                return [
                    "type": "text_file",
                    "name": attachment.name,
                    "mime": attachment.mimeType,
                    "size": attachment.fileSize,
                    "text": text
                ] as [String: Any]
            }
        }

        let storedAttachments = pendingAttachments
        let payloadText = trimmed

        withAnimation(DS.Motion.quickSpring) {
            messages.append(ChatMessage(id: UUID(), role: .user, text: payloadText, isStreaming: false, isFailed: false, remoteId: nil, attachments: storedAttachments))
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
            startStreaming(chatId: currentThreadId, model: modelId, messages: history, attachments: apiAttachments.isEmpty ? nil : apiAttachments)
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

    func addImageAttachment(image: UIImage, name: String = "Photo") {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return }
        let resized = Self.resizeImageData(jpegData, maxDimension: 2048)
        guard resized.count <= Self.MAX_IMAGE_SIZE else {
            latestError = "Image too large (max 8MB)."
            return
        }
        let displayName = "\(name) \(pendingAttachments.count + 1)"
        pendingAttachments.append(Attachment(
            id: UUID(), kind: .photo, name: displayName,
            imageData: resized, textContent: nil,
            mimeType: "image/jpeg", fileSize: resized.count
        ))
    }

    func addCameraAttachment(image: UIImage) {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return }
        let resized = Self.resizeImageData(jpegData, maxDimension: 2048)
        guard resized.count <= Self.MAX_IMAGE_SIZE else {
            latestError = "Photo too large (max 8MB)."
            return
        }
        pendingAttachments.append(Attachment(
            id: UUID(), kind: .camera, name: "Camera Photo",
            imageData: resized, textContent: nil,
            mimeType: "image/jpeg", fileSize: resized.count
        ))
    }

    func addFileAttachment(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            latestError = "Cannot access file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let filename = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        let imageExtensions = Set(["jpg", "jpeg", "png", "heic", "heif", "webp", "gif", "bmp", "tiff"])
        let textExtensions = Set(["txt", "md", "csv", "json", "xml", "yaml", "yml", "log", "swift", "py", "js", "ts", "html", "css", "c", "cpp", "h", "java", "kt", "rb", "go", "rs", "sh", "sql", "r"])

        guard let data = try? Data(contentsOf: url) else {
            latestError = "Could not read file."
            return
        }

        if imageExtensions.contains(ext) {
            guard let image = UIImage(data: data) else {
                latestError = "Could not load image."
                return
            }
            addImageAttachment(image: image, name: filename)
        } else if textExtensions.contains(ext) {
            guard data.count <= Self.MAX_TEXT_FILE_SIZE else {
                latestError = "Text file too large (max 1MB)."
                return
            }
            guard let text = String(data: data, encoding: .utf8) else {
                latestError = "File is not valid text."
                return
            }
            pendingAttachments.append(Attachment(
                id: UUID(), kind: .file, name: filename,
                imageData: nil, textContent: text,
                mimeType: "text/plain", fileSize: data.count
            ))
        } else if ext == "pdf" {
            guard data.count <= Self.MAX_TEXT_FILE_SIZE else {
                latestError = "PDF too large (max 1MB)."
                return
            }
            if let text = Self.extractTextFromPDF(url: url), !text.isEmpty {
                pendingAttachments.append(Attachment(
                    id: UUID(), kind: .file, name: filename,
                    imageData: nil, textContent: text,
                    mimeType: "text/plain", fileSize: text.utf8.count
                ))
            } else {
                latestError = "Could not extract text from PDF."
            }
        } else {
            latestError = "Unsupported file type: .\(ext)"
        }
    }

    private static func resizeImageData(_ data: Data, maxDimension: CGFloat) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return data }
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.jpegData(withCompressionQuality: 0.8) { ctx in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized
    }

    private static func extractTextFromPDF(url: URL) -> String? {
        guard let pdf = PDFDocument(url: url) else { return nil }
        var text = ""
        let pageCount = min(pdf.pageCount, 20)
        for i in 0..<pageCount {
            guard let page = pdf.page(at: i) else { continue }
            if let pageText = page.string {
                text += pageText + "\n"
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
    }

    func removeAttachment(_ attachment: Attachment) {
        pendingAttachments.removeAll { $0.id == attachment.id }
    }

    // MARK: - Generation Chat Support

    var selectedModelId: String? {
        modelIdProvider()
    }

    var isGenerationChat: Bool {
        guard let modelId = modelIdProvider() else { return false }
        return FalModel.isGenerationModel(modelId)
    }

    var generationMode: GenerationType? {
        guard let modelId = modelIdProvider() else { return nil }
        return FalModel.generationType(for: modelId)
    }

    @Published var generationImageSize: String = "square_hd"
    @Published var generationImageStyle: String = "photo"
    @Published var generationVideoDuration: String = "5"
    @Published var generationVideoResolution: String = "720p"

    private var generationService: FalAIServiceProtocol?
    private var generationPollingTask: Task<Void, Never>?

    func setGenerationService(_ service: FalAIServiceProtocol) {
        self.generationService = service
    }

    func sendGenerationMessage(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let modelId = modelIdProvider(), !modelId.isEmpty else { return }
        guard let mode = generationMode else { return }
        guard let service = generationService else {
            latestError = "Generation service not available. Please try again."
            return
        }
        guard ensureQuotaAvailable() else { return }
        latestError = nil

        // Add user message
        let userMsgId = UUID()
        withAnimation(DS.Motion.quickSpring) {
            messages.append(ChatMessage(id: userMsgId, role: .user, text: trimmed, isStreaming: false, isFailed: false))
        }

        // Add generating placeholder
        let assistantMsgId = UUID()
        let progressText = mode == .image ? "Creating your image..." : "Creating your video..."
        withAnimation(DS.Motion.quickSpring) {
            messages.append(ChatMessage(
                id: assistantMsgId, role: .assistant, text: "", isStreaming: false, isFailed: false,
                isGenerating: true, generationType: mode, generationProgress: progressText
            ))
        }

        do {
            let response: GenerationSubmitResponse
            if mode == .image {
                response = try await service.submitImage(
                    prompt: trimmed, negativePrompt: nil, modelId: modelId, chatId: nil,
                    imageSize: generationImageSize, numImages: 1, style: generationImageStyle
                )
            } else {
                response = try await service.submitVideo(
                    prompt: trimmed, negativePrompt: nil, modelId: modelId, chatId: nil,
                    duration: generationVideoDuration, resolution: generationVideoResolution, imageUrl: nil
                )
            }

            // Update generation ID — find by stable UUID, not index
            updateGenerationMessage(id: assistantMsgId) { $0.generationId = response.id }

            // Poll in a cancellable task
            generationPollingTask?.cancel()
            generationPollingTask = Task { [weak self] in
                await self?.pollGeneration(id: response.id, messageId: assistantMsgId, service: service, mode: mode)
            }
            await generationPollingTask?.value
        } catch {
            updateGenerationMessage(id: assistantMsgId) {
                $0.isGenerating = false
                $0.isFailed = true
                $0.generationProgress = nil
                $0.text = "Generation failed: \(error.localizedDescription)"
            }
        }
    }

    func cancelGeneration(messageId: UUID) {
        generationPollingTask?.cancel()
        generationPollingTask = nil
        guard let genId = messages.first(where: { $0.id == messageId })?.generationId else { return }
        updateGenerationMessage(id: messageId) {
            $0.isGenerating = false
            $0.isFailed = true
            $0.generationProgress = nil
            $0.text = "Generation cancelled."
        }
        let service = generationService
        Task { [weak self] in
            _ = self  // prevent unused warning
            try? await service?.cancel(generationId: genId)
        }
    }

    func regenerateGeneration(messageId: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        let userIdx = messages[..<idx].lastIndex(where: { $0.role == .user })
        guard let userIdx else { return }
        let prompt = messages[userIdx].text
        // Reset the result message to generating state instead of removing
        updateGenerationMessage(id: messageId) {
            $0.isGenerating = true
            $0.isFailed = false
            $0.generationResultUrl = nil
            $0.generationProgress = "Regenerating..."
            $0.generationId = nil
            $0.text = ""
        }
        Task { [weak self] in
            guard let self else { return }
            guard let modelId = self.modelIdProvider(), !modelId.isEmpty,
                  let mode = self.generationMode,
                  let service = self.generationService else { return }
            do {
                let response: GenerationSubmitResponse
                if mode == .image {
                    response = try await service.submitImage(
                        prompt: prompt, negativePrompt: nil, modelId: modelId, chatId: nil,
                        imageSize: self.generationImageSize, numImages: 1, style: self.generationImageStyle
                    )
                } else {
                    response = try await service.submitVideo(
                        prompt: prompt, negativePrompt: nil, modelId: modelId, chatId: nil,
                        duration: self.generationVideoDuration, resolution: self.generationVideoResolution, imageUrl: nil
                    )
                }
                self.updateGenerationMessage(id: messageId) { $0.generationId = response.id }
                self.generationPollingTask?.cancel()
                self.generationPollingTask = Task { [weak self] in
                    await self?.pollGeneration(id: response.id, messageId: messageId, service: service, mode: mode)
                }
                await self.generationPollingTask?.value
            } catch {
                self.updateGenerationMessage(id: messageId) {
                    $0.isGenerating = false
                    $0.isFailed = true
                    $0.generationProgress = nil
                    $0.text = "Regeneration failed: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Thread-safe mutation of a generation message by its stable UUID.
    private func updateGenerationMessage(id: UUID, update: (inout ChatMessage) -> Void) {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        update(&messages[idx])
    }

    private func pollGeneration(id: String, messageId: UUID, service: FalAIServiceProtocol, mode: GenerationType) async {
        let interval: UInt64 = mode == .image ? 2_000_000_000 : 4_000_000_000
        let maxAttempts = mode == .image ? 60 : 120

        for _ in 0..<maxAttempts {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: interval)
            guard !Task.isCancelled else { return }

            do {
                let status = try await service.checkStatus(generationId: id)

                switch status.status {
                case "completed":
                    updateGenerationMessage(id: messageId) {
                        $0.isGenerating = false
                        $0.generationResultUrl = status.resultUrl
                        $0.generationProgress = nil
                    }
                    Haptics.impact(.soft)
                    return
                case "failed":
                    updateGenerationMessage(id: messageId) {
                        $0.isGenerating = false
                        $0.isFailed = true
                        $0.generationProgress = nil
                        $0.text = status.errorMessage ?? "Generation failed."
                    }
                    return
                case "processing":
                    updateGenerationMessage(id: messageId) { $0.generationProgress = "Almost ready..." }
                default:
                    if let pos = status.queuePosition, pos > 0 {
                        updateGenerationMessage(id: messageId) { $0.generationProgress = "Queue position: \(pos)" }
                    }
                }
            } catch {
                // Transient error, keep polling
            }
        }

        // Timeout
        updateGenerationMessage(id: messageId) {
            $0.isGenerating = false
            $0.isFailed = true
            $0.generationProgress = nil
            $0.text = "Generation timed out. Please try again."
        }
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
        
        // Validate each attachment has actual data
        for attachment in attachments {
            switch attachment.kind {
            case .photo, .camera:
                guard attachment.imageData != nil else {
                    throw AttachmentValidationError(message: "'\(attachment.name)' has no image data.")
                }
                if attachment.fileSize > Self.MAX_IMAGE_SIZE {
                    throw AttachmentValidationError(message: "'\(attachment.name)' is too large (max 8MB).")
                }
            case .file:
                guard attachment.textContent != nil else {
                    throw AttachmentValidationError(message: "'\(attachment.name)' has no content.")
                }
                if attachment.fileSize > Self.MAX_TEXT_FILE_SIZE {
                    throw AttachmentValidationError(message: "'\(attachment.name)' is too large (max 1MB).")
                }
            }
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

    private func startStreaming(chatId: String, model: String, messages: [ChatMessageSummary], attachments: [[String: Any]]? = nil) {
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
                let streamedMessageId = try await self.streamWithRetryOnce(chatId: chatId, model: model, messages: messages, attachments: attachments, messageID: messageID)
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
                // Handle rate limit / quota errors with creative UI
                if let taiError = error as? TABAIError, taiError.isRateLimited {
                    // Remove the empty assistant message
                    self.messages.removeAll { $0.id == messageID }
                    self.isStreaming = false
                    self.streamingPhase = .idle
                    self.streamingTask = nil
                    // Show the creative limit-reached sheet
                    let code = taiError.rateLimitCode ?? ""
                    let modelName = self.modelIdProvider()?.components(separatedBy: "/").last?.capitalized ?? "this model"
                    switch code {
                    case "CHAT_DAILY_CATEGORY_LIMIT":
                        self.limitReachedType = .chatDailyCategory(modelName: modelName, used: 0, limit: 0)
                    case "CHAT_CATEGORY_LOCKED":
                        self.limitReachedType = .chatModelLocked(modelName: modelName, requiredTier: "Pro")
                    case "MODEL_LOCKED", "UPGRADE_REQUIRED_EXPENSIVE_MODEL":
                        self.limitReachedType = .chatModelLocked(modelName: modelName, requiredTier: "Pro")
                    default:
                        self.limitReachedType = .chatDailyCategory(modelName: modelName, used: 0, limit: 0)
                    }
                    self.showLimitReached = true
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

    private func streamWithRetryOnce(chatId: String, model: String, messages: [ChatMessageSummary], attachments: [[String: Any]]? = nil, messageID: UUID) async throws -> String? {
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
                streamedMessageId = try await chatService.streamChat(chatId: chatId, model: model, messages: messages, attachments: attachments, onToken: { delta in
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
