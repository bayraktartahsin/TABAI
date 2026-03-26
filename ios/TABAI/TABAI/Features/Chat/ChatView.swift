import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.openURL) private var openURL
    @Environment(\.shellOpenDrawer) private var openDrawer
    @ObservedObject private var persistence = PersistenceController.shared
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var voiceInputViewModel = VoiceSessionViewModel()
    @State private var composerText: String = ""
    @State private var showComposerToolsSheet: Bool = false
    @State private var showAuthEntrySheet: Bool = false
    @State private var showImageGenerator: Bool = false
    @State private var showVideoGenerator: Bool = false
    @State private var showVoiceDisabledAlert: Bool = false
    @State private var scrollToBottomTrigger: Int = 0
    @State private var scrollViewportHeight: CGFloat = 0
    @State private var bottomAnchorMaxY: CGFloat = 0
    @State private var isNearBottom: Bool = true
    @State private var isKeyboardPresented: Bool = false
    @State private var lastVoiceTranscriptId: UUID?
    @AppStorage("tai.voiceSessionEnabled") private var voiceSessionEnabled = false
    @AppStorage("tai.hasAcceptedAIDataSharing") private var hasAcceptedAIDataSharing = false
    @State private var showAIConsentSheet: Bool = false
    @State private var aiConsentLegalDestination: LegalLinkDestination?
    @State private var fullScreenGenerationMessage: ChatViewModel.ChatMessage?
    @State private var showPhotoPicker: Bool = false
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showCamera: Bool = false
    @State private var capturedCameraImage: UIImage?
    @State private var showDocumentPicker: Bool = false
    @State private var isVisionModelSwitch: Bool = false

    private let suggestions = [
        "Explain quantum computing simply",
        "Plan a 3-day Istanbul trip",
        "Write a Python web scraper",
        "Compare React vs SwiftUI",
        "Summarize this article for me",
        "Help me debug my code"
    ]

    init() {
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            chatService: MockChatService(),
            modelIdProvider: { nil },
            isAuthenticatedProvider: { false },
            persistence: PersistenceController.shared
        ))
    }

    init(chatService: ChatServiceProtocol, modelIdProvider: @escaping () -> String?, isAuthenticatedProvider: @escaping () -> Bool = { true }) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            chatService: chatService,
            modelIdProvider: modelIdProvider,
            isAuthenticatedProvider: isAuthenticatedProvider,
            persistence: PersistenceController.shared
        ))
    }


    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 12)
                .padding(.bottom, 2)

            if viewModel.isLoadingChat {
                loadingState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            } else if viewModel.messages.isEmpty {
                if viewModel.isGenerationChat, let mode = viewModel.generationMode {
                    GenerationWelcomeCard(generationType: mode) { suggestion in
                        composerText = suggestion
                        handleSend()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                } else {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .transition(.opacity)
                }
            } else {
                messageList
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, DS.Layout.horizontalPadding)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomComposerStack
                .padding(.horizontal, DS.Layout.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background {
                    ZStack(alignment: .top) {
                        // Solid background that covers the composer area
                        Color(uiColor: UIColor { trait in
                            trait.userInterfaceStyle == .dark
                                ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
                                : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1)
                        })
                        // Fade-in gradient at the very top edge for a smooth transition
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Color(uiColor: UIColor { trait in
                                    trait.userInterfaceStyle == .dark
                                        ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
                                        : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1)
                                }), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 20)
                    }
                    .ignoresSafeArea(.all, edges: .bottom)
                }
        }
        .taiFullscreen {
            GradientBackground()
        }
        .onAppear {
            viewModel.configureUsageQuota(
                planTierProvider: { appEnvironment.effectiveCurrentPlanTier },
                onQuotaExceeded: {
                    Haptics.impact(.light)
                    appEnvironment.selectedTab = .subscriptions
                }
            )
            viewModel.configureModelCapabilities { [weak appEnvironment] modelId in
                appEnvironment?.availableModels.first(where: { $0.id == modelId })?.capabilities ?? []
            }
            viewModel.startDemoIfNeeded()
            viewModel.setGenerationService(appEnvironment.generationService)
            if isSignedIn && !hasAcceptedAIDataSharing {
                showAIConsentSheet = true
            }
        }
        .onChange(of: appEnvironment.selectedThreadId) { oldValue, newValue in
            guard oldValue != newValue else { return }
            viewModel.prepareForThreadSwitchIfNeeded()
            guard let threadId = newValue, !threadId.isEmpty else { return }
            Task {
                await viewModel.loadChat(threadId: threadId)
            }
        }
        .onChange(of: appEnvironment.selectedModelId) { oldValue, newValue in
            guard oldValue != nil, oldValue != newValue else { return }
            // Skip chat reset when switching model for vision capability
            if isVisionModelSwitch {
                isVisionModelSwitch = false
                return
            }
            viewModel.beginNewChatForModelSwitch()
            appEnvironment.selectedThreadId = nil
            appEnvironment.selectedTab = .chat
        }
        .onChange(of: appEnvironment.featureFlags.useTABAI) { _, _ in
            viewModel.updateChatService(appEnvironment.chatService)
        }
        .sheet(isPresented: $showComposerToolsSheet) {
            ComposerToolsSheet(
                onSelectPhoto: {
                    showComposerToolsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showPhotoPicker = true
                    }
                },
                onSelectCamera: {
                    showComposerToolsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showCamera = true
                    }
                },
                onSelectFile: {
                    showComposerToolsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showDocumentPicker = true
                    }
                }
            )
            .presentationDetents([.height(320)])
            .taiSheetChrome()
        }
        .sheet(isPresented: $showImageGenerator) {
            ImageGeneratorView(service: appEnvironment.generationService)
                .environmentObject(appEnvironment)
        }
        .sheet(isPresented: $showVideoGenerator) {
            VideoGeneratorView(service: appEnvironment.generationService)
                .environmentObject(appEnvironment)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItems, maxSelectionCount: max(1, 6 - viewModel.pendingAttachments.count), matching: .images)
        .onChange(of: photoPickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await processPickedPhotos(items) }
            photoPickerItems = []
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(image: $capturedCameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedCameraImage) { _, newImage in
            guard let image = newImage else { return }
            capturedCameraImage = nil
            viewModel.addCameraAttachment(image: image)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { urls in
                for url in urls {
                    viewModel.addFileAttachment(url: url)
                }
            }
        }
        .sheet(isPresented: $showAuthEntrySheet) {
            SignInView(viewModel: SignInViewModel())
                .presentationDetents([.large])
                .taiSheetChrome()
        }
        .sheet(isPresented: $viewModel.showVisionRequired) {
            VisionRequiredSheet(
                currentModelName: appEnvironment.availableModels.first(where: { $0.id == appEnvironment.selectedModelId })?.displayName,
                visionModels: appEnvironment.availableModels.filter { $0.capabilities.contains("vision") && $0.canAccess },
                onSelectModel: { modelId in
                    isVisionModelSwitch = true
                    appEnvironment.selectedModelId = modelId
                    // Re-send after model switch with short delay for model to take effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        viewModel.resendAfterVisionResolved()
                    }
                },
                onRemoveImages: {
                    viewModel.removeImagesAndResend()
                },
                onOpenPlans: {
                    appEnvironment.selectedTab = .subscriptions
                }
            )
            .presentationDetents([.medium, .large])
            .taiSheetChrome()
        }
        .sheet(isPresented: $viewModel.showLimitReached) {
            if let limitType = viewModel.limitReachedType {
                LimitReachedSheet(
                    type: limitType,
                    onUpgrade: {
                        viewModel.showLimitReached = false
                        appEnvironment.selectedTab = .subscriptions
                    },
                    onDismiss: {
                        viewModel.showLimitReached = false
                    }
                )
                .presentationDetents([.medium])
                .taiSheetChrome()
            }
        }
        .alert("Voice Input Disabled", isPresented: $showVoiceDisabledAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Turn on Voice Input in Settings to use dictation.")
        }
        .fullScreenCover(isPresented: $showAIConsentSheet) {
            aiDataSharingConsentView
        }
        .fullScreenCover(item: $fullScreenGenerationMessage) { message in
            GenerationFullScreenViewer(
                resultUrl: message.generationResultUrl ?? "",
                generationType: message.generationType ?? .image,
                prompt: findUserPrompt(for: message)
            )
        }
        .onChange(of: voiceInputViewModel.transcript) { _, lines in
            guard let latest = lines.last else { return }
            guard latest.id != lastVoiceTranscriptId else { return }
            lastVoiceTranscriptId = latest.id

            let trimmed = latest.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            if composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                composerText = trimmed
            } else if !composerText.localizedCaseInsensitiveContains(trimmed) {
                composerText = "\(composerText) \(trimmed)"
            }
        }
        .onChange(of: voiceSessionEnabled) { _, enabled in
            guard !enabled else { return }
            if voiceInputViewModel.isListening {
                voiceInputViewModel.stopListening()
            }
            voiceInputViewModel.clearDraft()
        }
        .onChange(of: appEnvironment.session?.isAuthenticated == true) { _, isAuthed in
            guard isAuthed else { return }
            showAuthEntrySheet = false
        }
        .animation(DS.Motion.quickSpring, value: viewModel.messages)
        .animation(DS.Motion.quickSpring, value: viewModel.latestError)
        .animation(DS.Motion.quickSpring, value: isNearBottom)
        .animation(DS.Motion.quickSpring, value: showInlineVoicePanel)
        .onReceive(keyboardWillShow) { _ in
            isKeyboardPresented = true
        }
        .onReceive(keyboardWillHide) { _ in
            isKeyboardPresented = false
        }
    }

    private var bottomComposerStack: some View {
        VStack(spacing: 0) {
            if let latestError = viewModel.latestError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(latestError)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(DS.Colors.fieldBackground.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(DS.Colors.glassStroke, lineWidth: 1)
                )
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if !isNearBottom && !viewModel.messages.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        scrollToBottomTrigger += 1
                    } label: {
                        Label("Jump to latest", systemImage: "arrow.down.to.line")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DS.Colors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(DS.Colors.fieldBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(DS.Colors.glassStroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showInlineVoicePanel {
                inlineVoicePanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if !isSignedIn {
                signedOutLockCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            ComposerView(
                text: $composerText,
                isStreaming: viewModel.isStreaming,
                attachments: viewModel.pendingAttachments,
                ambientPlanLine: composerAmbientPlanLine,
                isVoiceSessionEnabled: voiceSessionEnabled,
                isVoiceListening: voiceInputViewModel.isListening,
                isLocked: !isSignedIn,
                onAttach: {
                    guard isSignedIn else {
                        showAuthEntrySheet = true
                        return
                    }
                    showComposerToolsSheet = true
                },
                onMic: {
                    guard isSignedIn else {
                        showAuthEntrySheet = true
                        return
                    }
                    guard voiceSessionEnabled else {
                        showVoiceDisabledAlert = true
                        return
                    }

                    if voiceInputViewModel.isListening {
                        voiceInputViewModel.stopListening()
                    } else {
                        voiceInputViewModel.refreshRecognizerLocale()
                        Task {
                            await voiceInputViewModel.startListening()
                        }
                    }
                },
                onSend: handleSend,
                onStop: { viewModel.stopStreaming() },
                onRemoveAttachment: viewModel.removeAttachment,
                onOpenPlans: {
                    appEnvironment.selectedTab = .subscriptions
                },
                onDismissKeyboard: {
                    dismissKeyboard()
                }
            )
            .padding(.top, 8)
        }
    }

    private var isSignedIn: Bool {
        appEnvironment.session?.isAuthenticated == true && !appEnvironment.isAuthenticating
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.impact(.light)
                openDrawer()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open drawer")

            Spacer()

            AnimatedBrandText(fontSize: 17)

            Spacer()

            if shouldShowNewChatButton {
                Button {
                    viewModel.beginNewChat()
                    appEnvironment.selectedThreadId = nil
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.Colors.textPrimary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start new chat")
            } else {
                Color.clear
                    .frame(width: 36, height: 36)
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        if message.isGenerating {
                            GenerationStatusView(
                                generationType: message.generationType ?? .image,
                                progress: message.generationProgress,
                                onCancel: { viewModel.cancelGeneration(messageId: message.id) }
                            )
                        } else if let resultUrl = message.generationResultUrl {
                            GenerationResultBubbleView(
                                resultUrl: resultUrl,
                                generationType: message.generationType ?? .image,
                                onRegenerate: { viewModel.regenerateGeneration(messageId: message.id) },
                                onFullScreen: { fullScreenGenerationMessage = message }
                            )
                        } else {
                            ChatBubbleView(
                                message: message,
                                streamingPhase: viewModel.streamingPhase,
                                stopPulseTrigger: viewModel.stopPulseTrigger,
                                isPrimaryStreamingBubble: message.id == viewModel.messages.last(where: { $0.role == .assistant })?.id,
                                onCopy: { UIPasteboard.general.string = message.text },
                                onEdit: { composerText = message.text },
                                onRegenerate: viewModel.regenerateLastAssistant,
                                onStop: viewModel.stopStreaming,
                                onRetry: viewModel.retryLastFailed
                            )
                        }
                    }

                    Color.clear
                        .frame(height: 1)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ChatBottomAnchorMaxYPreferenceKey.self,
                                    value: geo.frame(in: .named("chat-scroll-space")).maxY
                                )
                            }
                        )
                        .id("chat-bottom-anchor")
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .coordinateSpace(name: "chat-scroll-space")
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ChatViewportHeightPreferenceKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(ChatViewportHeightPreferenceKey.self) { newValue in
                scrollViewportHeight = newValue
                updateNearBottomState()
            }
            .onPreferenceChange(ChatBottomAnchorMaxYPreferenceKey.self) { newValue in
                bottomAnchorMaxY = newValue
                updateNearBottomState()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                guard isNearBottom else { return }
                withAnimation(DS.Motion.quickSpring) {
                    proxy.scrollTo("chat-bottom-anchor", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.streamRenderTick) { _, _ in
                guard isNearBottom else { return }
                withAnimation(DS.Motion.quickSpring) {
                    proxy.scrollTo("chat-bottom-anchor", anchor: .bottom)
                }
            }
            .onChange(of: scrollToBottomTrigger) { _, _ in
                withAnimation(DS.Motion.quickSpring) {
                    proxy.scrollTo("chat-bottom-anchor", anchor: .bottom)
                }
            }
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                // Animated TAI brain logo
                AnimatedBrandLogo()
                    .padding(.bottom, 8)

                // Perplexity-style centered prompt
                VStack(spacing: 8) {
                    Text(isSignedIn ? L("Ask anything") : "Welcome to TABAI")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(DS.Colors.textPrimary)

                    if !isSignedIn {
                        Text("Sign in to start your first conversation")
                            .font(.system(size: 15))
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                }
                .padding(.bottom, 28)

                // Suggestion chips (2-column grid)
                if isSignedIn {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                composerText = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(DS.Colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(suggestionChipBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(suggestionChipBorder, lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if shouldShowPremiumEmptyState {
                    Button {
                        Haptics.impact(.light)
                        appEnvironment.selectedTab = .subscriptions
                    } label: {
                        Text("Explore Plans")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.Colors.accent)
                            .padding(.top, 20)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 4)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var suggestionChipBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor.black.withAlphaComponent(0.03)
        })
    }

    private var suggestionChipBorder: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.06)
        })
    }

    private func updateNearBottomState() {
        guard scrollViewportHeight > 0 else {
            isNearBottom = true
            return
        }
        let distanceFromBottom = bottomAnchorMaxY - scrollViewportHeight
        isNearBottom = distanceFromBottom <= 140
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 14) {
            SkeletonBlock(height: 18, width: 178)
            SkeletonBlock(height: 14, width: 236)

            VStack(spacing: 10) {
                HStack {
                    SkeletonBlock(height: 14, width: 190)
                    Spacer(minLength: 34)
                }
                HStack {
                    Spacer(minLength: 34)
                    SkeletonBlock(height: 14, width: 210)
                }
                HStack {
                    SkeletonBlock(height: 14, width: 154)
                    Spacer(minLength: 34)
                }
            }

            Text("Loading conversation")
                .font(.caption)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .padding(18)
        .background(DS.Colors.fieldBackground.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DS.Colors.glassStroke, lineWidth: 1)
        )
        .padding(.top, 16)
    }

    private func handleSend() {
        guard isSignedIn else {
            showAuthEntrySheet = true
            return
        }
        guard hasAcceptedAIDataSharing else {
            showAIConsentSheet = true
            return
        }
        let textToSend = composerText
        composerText = ""
        if viewModel.isGenerationChat {
            Task { await viewModel.sendGenerationMessage(text: textToSend) }
        } else {
            viewModel.send(text: textToSend)
        }
    }

    private func findUserPrompt(for message: ChatViewModel.ChatMessage) -> String {
        guard let idx = viewModel.messages.firstIndex(where: { $0.id == message.id }) else { return "" }
        let userMsg = viewModel.messages[..<idx].last(where: { $0.role == .user })
        return userMsg?.text ?? ""
    }

    private func processPickedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            guard let image = UIImage(data: data) else { continue }
            viewModel.addImageAttachment(image: image, name: "Photo")
        }
    }

    private var composerAmbientPlanLine: String? {
        guard isSignedIn else { return nil }
        let tier = appEnvironment.effectiveCurrentPlanTier
        let plan = SubscriptionPlanCatalog.displayName(for: tier)
        let modelName = currentModelDisplayName
        if tier == .free {
            return "\(modelName)  ·  \(L("Free plan"))"
        }
        return "\(modelName)  ·  \(plan)"
    }

    private var showInlineVoicePanel: Bool {
        guard isSignedIn else { return false }
        return voiceInputViewModel.isListening ||
            voiceInputViewModel.permissionState == .denied ||
            voiceInputViewModel.errorMessage != nil
    }

    private var signedOutLockCard: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(DS.Colors.accent)

            VStack(alignment: .leading, spacing: 3) {
                Text("Sign in to start chatting")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("The composer is ready. Responses, tools, and history unlock after sign-in.")
                    .font(.caption2)
                    .foregroundStyle(DS.Colors.textSecondary)
            }

            Spacer(minLength: 8)

            Button("Sign In") {
                Haptics.impact(.light)
                showAuthEntrySheet = true
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(DS.Colors.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DS.Colors.fieldBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Colors.glassStroke, lineWidth: 1)
        )
        .padding(.top, 8)
    }

    private var inlineVoicePanel: some View {
        HStack(spacing: 10) {
            if voiceInputViewModel.permissionState == .denied {
                Image(systemName: "mic.slash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.orange)
                Text("Microphone access denied")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textSecondary)
                Spacer()
                Button("Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.accent)
            } else if voiceInputViewModel.isListening {
                // Pulsing dot + "Listening..." — minimal like Perplexity
                Circle()
                    .fill(DS.Colors.accent)
                    .frame(width: 8, height: 8)
                    .modifier(PulseModifier())
                Text("Listening...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                Button {
                    Haptics.impact(.light)
                    voiceInputViewModel.stopListening()
                } label: {
                    Text("Done")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                }
            } else if let err = voiceInputViewModel.errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DS.Colors.fieldBackground.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.top, 6)
    }

    private var aiDataSharingConsentView: some View {
        ZStack {
            GradientBackground().ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 48))
                    .foregroundStyle(DS.Colors.accent)

                Text("AI Data Sharing Notice")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DS.Colors.textPrimary)

                Text("TABAI sends your messages to third-party AI model providers (such as OpenAI, Anthropic, Google, Meta, and Mistral) to generate responses.\n\nYour prompts and conversation content are transmitted to these providers for processing. No personal account data beyond your messages is shared.\n\nAI providers may process data according to their own privacy policies. You can review our full privacy policy for details.")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        aiConsentLegalDestination = LegalLinkDestination(key: .privacy)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 14))
                            Text("View Privacy Policy")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(DS.Colors.accent)
                        .background(DS.Colors.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(DS.Colors.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        hasAcceptedAIDataSharing = true
                        showAIConsentSheet = false
                    } label: {
                        Text("I Understand & Agree")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.black)
                            .background(DS.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .sheet(item: $aiConsentLegalDestination) { destination in
            InAppSafariView(url: destination.url)
                .ignoresSafeArea()
        }
        .interactiveDismissDisabled()
    }

    private var currentModelDisplayName: String {
        guard let selectedModelId = appEnvironment.selectedModelId, selectedModelId.isEmpty == false else {
            return "Model"
        }
        if let model = appEnvironment.availableModels.first(where: { $0.id == selectedModelId }) {
            return model.displayName ?? model.id
        }
        return selectedModelId
    }

    private var shouldShowPremiumEmptyState: Bool {
        isSignedIn && appEnvironment.effectiveCurrentPlanTier == .free && persistence.threads.isEmpty
    }

    private var shouldShowNewChatButton: Bool {
        isSignedIn && (!viewModel.messages.isEmpty || appEnvironment.selectedThreadId != nil)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var keyboardWillShow: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    }

    private var keyboardWillHide: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    }
}


private struct ComposerToolsSheet: View {
    let onSelectPhoto: () -> Void
    let onSelectCamera: () -> Void
    let onSelectFile: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Attach")
                    .font(DS.Typography.subtitle)
                    .foregroundStyle(DS.Colors.textPrimary)

                ToolActionRow(
                    icon: "photo",
                    title: "Image",
                    subtitle: "Attach a photo to your next prompt.",
                    action: onSelectPhoto
                )

                ToolActionRow(
                    icon: "camera",
                    title: "Camera",
                    subtitle: "Take a photo and attach it.",
                    action: onSelectCamera
                )

                ToolActionRow(
                    icon: "doc",
                    title: "File",
                    subtitle: "Attach a document to your prompt.",
                    action: onSelectFile
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, DS.Layout.horizontalPadding)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .taiFullscreen {
                GradientBackground()
            }
            .navigationTitle("Attachments")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ToolComingSoonRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.Colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(DS.Colors.fieldBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.Typography.body.weight(.semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            Text("Soon")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DS.Colors.fieldBackground)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Colors.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Colors.glassStroke, lineWidth: 1)
        )
        .opacity(0.85)
    }
}

private struct ToolActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.Typography.body.weight(.semibold))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Colors.glassStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ChatViewportHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ChatBottomAnchorMaxYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.4 : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - Camera Capture

private struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        init(_ parent: CameraCaptureView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Document Picker

private struct DocumentPickerView: UIViewControllerRepresentable {
    let onPicked: ([URL]) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.image, .plainText, .json, .yaml, .xml, .sourceCode, .pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        init(_ parent: DocumentPickerView) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPicked(urls)
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
