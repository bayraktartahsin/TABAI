import SwiftUI
import UIKit

private struct ShellOpenDrawerKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var shellOpenDrawer: () -> Void {
        get { self[ShellOpenDrawerKey.self] }
        set { self[ShellOpenDrawerKey.self] = newValue }
    }
}

struct NavigationShellView<Content: View>: View {
    @State private var isDrawerOpen: Bool = false
    @State private var dragTranslation: CGFloat = 0

    private let content: Content
    private let conversations: [ChatThreadRecord]
    private let selectedThreadId: String?
    private let onSelectConversation: (String) -> Void
    private let accountEmail: String?
    private let accountPlanLabel: String
    private let onTogglePin: (ChatThreadRecord) -> Void
    private let onRenameConversation: (ChatThreadRecord, String) -> Void
    private let onDeleteConversation: (ChatThreadRecord) -> Void
    private let onNewChat: () -> Void
    private let onSettings: () -> Void
    private let onSubscription: () -> Void
    private let folders: [ChatFolderSummary]
    private let onCreateFolder: (String) -> Void
    private let onDeleteFolder: (ChatFolderSummary, Bool) -> Void
    private let onAssignConversationToFolder: (ChatThreadRecord, String) -> Void

    init(
        @ViewBuilder content: () -> Content,
        conversations: [ChatThreadRecord] = [],
        selectedThreadId: String? = nil,
        onSelectConversation: @escaping (String) -> Void = { _ in },
        accountEmail: String? = nil,
        accountPlanLabel: String = "Free",
        onTogglePin: @escaping (ChatThreadRecord) -> Void = { _ in },
        onRenameConversation: @escaping (ChatThreadRecord, String) -> Void = { _, _ in },
        onDeleteConversation: @escaping (ChatThreadRecord) -> Void = { _ in },
        onNewChat: @escaping () -> Void = {},
        onSettings: @escaping () -> Void = {},
        onSubscription: @escaping () -> Void = {},
        folders: [ChatFolderSummary] = [],
        onCreateFolder: @escaping (String) -> Void = { _ in },
        onDeleteFolder: @escaping (ChatFolderSummary, Bool) -> Void = { _, _ in },
        onAssignConversationToFolder: @escaping (ChatThreadRecord, String) -> Void = { _, _ in }
    ) {
        self.content = content()
        self.conversations = conversations
        self.selectedThreadId = selectedThreadId
        self.onSelectConversation = onSelectConversation
        self.accountEmail = accountEmail
        self.accountPlanLabel = accountPlanLabel
        self.onTogglePin = onTogglePin
        self.onRenameConversation = onRenameConversation
        self.onDeleteConversation = onDeleteConversation
        self.onNewChat = onNewChat
        self.onSettings = onSettings
        self.onSubscription = onSubscription
        self.folders = folders
        self.onCreateFolder = onCreateFolder
        self.onDeleteFolder = onDeleteFolder
        self.onAssignConversationToFolder = onAssignConversationToFolder
    }

    var body: some View {
        GeometryReader { proxy in
            let drawerWidth = min(320, proxy.size.width * 0.82)
            let constrainedTranslation = constrainedDragTranslation(for: drawerWidth)
            let drawerProgress = progress(for: drawerWidth, translation: constrainedTranslation)

            ZStack(alignment: .leading) {
                content
                    .environment(\.shellOpenDrawer, { openDrawer() })

                if drawerProgress > 0 {
                    Color.black
                        .opacity(0.35 * drawerProgress)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .allowsHitTesting(drawerProgress > 0.01)
                        .onTapGesture {
                            closeDrawer()
                        }
                }

                ConversationDrawerView(
                    conversations: conversations,
                    selectedThreadId: selectedThreadId,
                    onSelectConversation: { threadId in
                        onSelectConversation(threadId)
                        closeDrawer()
                    },
                    accountEmail: accountEmail,
                    planLabel: accountPlanLabel,
                    onTogglePin: onTogglePin,
                    onRenameConversation: onRenameConversation,
                    onDeleteConversation: onDeleteConversation,
                    onNewChat: {
                        onNewChat()
                        closeDrawer()
                    },
                    onSettings: {
                        onSettings()
                        closeDrawer()
                    },
                    onSubscription: {
                        onSubscription()
                        closeDrawer()
                    },
                    folders: folders,
                    onCreateFolder: onCreateFolder,
                    onDeleteFolder: onDeleteFolder,
                    onAssignConversationToFolder: onAssignConversationToFolder
                )
                .frame(width: drawerWidth)
                .frame(maxHeight: .infinity)
                .background(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 20, x: 4, y: 0)
                .offset(x: drawerOffset(for: drawerWidth, translation: constrainedTranslation))
                .gesture(drawerCloseGesture(width: drawerWidth))

                if !isDrawerOpen {
                    Color.clear
                        .frame(width: 24)
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .gesture(edgeOpenGesture(width: drawerWidth))
                        .allowsHitTesting(true)
                }
            }
            .animation(.easeInOut(duration: 0.24), value: isDrawerOpen)
        }
    }

    private func drawerOffset(for width: CGFloat, translation: CGFloat) -> CGFloat {
        let base: CGFloat = isDrawerOpen ? 0 : -width
        return base + translation
    }

    private func progress(for width: CGFloat, translation: CGFloat) -> CGFloat {
        let visible = (isDrawerOpen ? width : 0) + translation
        return max(0, min(1, visible / width))
    }

    private func constrainedDragTranslation(for width: CGFloat) -> CGFloat {
        if isDrawerOpen {
            return max(-width, min(0, dragTranslation))
        }
        return max(0, min(width, dragTranslation))
    }

    private func edgeOpenGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragTranslation = max(0, value.translation.width)
            }
            .onEnded { value in
                let shouldOpen = value.translation.width > width * 0.35 || value.predictedEndTranslation.width > width * 0.5
                dragTranslation = 0
                if shouldOpen {
                    openDrawer()
                }
            }
    }

    private func drawerCloseGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard isDrawerOpen else { return }
                dragTranslation = min(0, value.translation.width)
            }
            .onEnded { value in
                guard isDrawerOpen else {
                    dragTranslation = 0
                    return
                }
                let shouldClose = value.translation.width < -width * 0.30 || value.predictedEndTranslation.width < -width * 0.45
                dragTranslation = 0
                if shouldClose {
                    closeDrawer()
                }
            }
    }

    private func openDrawer() {
        guard !isDrawerOpen else { return }
        isDrawerOpen = true
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.prepare()
        feedback.impactOccurred()
    }

    private func closeDrawer() {
        isDrawerOpen = false
    }
}
