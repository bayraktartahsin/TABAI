import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @AppStorage("tai.themePreference") private var themePreference = "system"

    var body: some View {
        ZStack {
            if appEnvironment.session?.isAuthenticated == true && appEnvironment.requiresBiometricUnlock {
                BiometricLockView()
                    .transition(.opacity)
            } else {
                MainShellView(appEnvironment: appEnvironment)
                    .transition(.opacity)
            }
        }
        .animation(DS.Motion.quickSpring, value: appEnvironment.session?.isAuthenticated == true)
        .animation(DS.Motion.quickSpring, value: appEnvironment.requiresBiometricUnlock)
        .preferredColorScheme(preferredColorScheme)
        .task {
            await appEnvironment.refreshConversations()
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch themePreference.lowercased() {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}

private struct BiometricLockView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @State private var isUnlocking = false

    var body: some View {
        VStack(spacing: 20) {
            Text("TABAI")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)
            Text("Unlock with \(appEnvironment.biometricLabel)")
                .font(DS.Typography.subtitle)
                .foregroundStyle(DS.Colors.textSecondary)
            PrimaryButton(
                title: "Unlock",
                isLoading: isUnlocking,
                isDisabled: false
            ) {
                Task {
                    isUnlocking = true
                    _ = await appEnvironment.unlockWithBiometrics()
                    isUnlocking = false
                }
            }
            Button("Sign Out") {
                appEnvironment.signOut()
            }
            .font(DS.Typography.body)
            .foregroundStyle(.red)
        }
        .padding(.horizontal, DS.Layout.horizontalPadding)
        .taiFullscreen {
            GradientBackground()
        }
    }
}

private struct MainShellView: View {
    @ObservedObject var appEnvironment: AppEnvironment
    @ObservedObject private var persistence = PersistenceController.shared
    @AppStorage("tai.themePreference") private var themePreference = "system"
    @State private var managementNotice: String?
    @State private var folders: [ChatFolderSummary] = []

    var body: some View {
        NavigationShellView(
            content: {
                ChatView(
                    chatService: appEnvironment.chatService,
                    modelIdProvider: { appEnvironment.selectedModelId },
                    isAuthenticatedProvider: { appEnvironment.session?.isAuthenticated == true && !appEnvironment.isAuthenticating }
                )
            },
            conversations: persistence.threads,
            selectedThreadId: appEnvironment.selectedThreadId,
            onSelectConversation: { remoteId in
                appEnvironment.selectedTab = .chat
                guard appEnvironment.selectedThreadId != remoteId else { return }
                appEnvironment.selectedThreadId = remoteId
            },
            accountEmail: appEnvironment.session?.email,
            accountPlanLabel: SubscriptionPlanCatalog.displayName(for: appEnvironment.effectiveCurrentPlanTier),
            onTogglePin: { thread in
                togglePin(for: thread)
            },
            onRenameConversation: { thread, newTitle in
                renameConversation(thread, to: newTitle)
            },
            onDeleteConversation: { thread in
                removeConversation(thread)
            },
            onNewChat: {
                appEnvironment.selectedTab = .chat
                appEnvironment.selectedThreadId = nil
            },
            onSettings: {
                appEnvironment.selectedTab = .settings
            },
            onSubscription: {
                appEnvironment.selectedTab = .subscriptions
            },
            folders: folders,
            onCreateFolder: { name in
                createFolder(named: name)
            },
            onDeleteFolder: { folder, deleteChats in
                deleteProject(folder, deleteChats: deleteChats)
            },
            onAssignConversationToFolder: { thread, folderId in
                assignConversation(thread, to: folderId)
            }
        )
        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: Binding(
            get: { appEnvironment.selectedTab == .settings },
            set: { isPresented in
                if !isPresented, appEnvironment.selectedTab == .settings {
                    appEnvironment.selectedTab = .chat
                }
            }
        )) {
            SettingsView()
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.large])
                .taiSheetChrome()
        }
        .sheet(isPresented: Binding(
            get: { appEnvironment.selectedTab == .subscriptions },
            set: { isPresented in
                if !isPresented, appEnvironment.selectedTab == .subscriptions {
                    appEnvironment.selectedTab = .chat
                }
            }
        )) {
            SubscriptionView()
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.large])
                .taiSheetChrome()
        }
        .alert("Conversation Action", isPresented: Binding(
            get: { managementNotice != nil },
            set: { isPresented in
                if !isPresented {
                    managementNotice = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                managementNotice = nil
            }
        } message: {
            Text(managementNotice ?? "")
        }
        .task {
            await loadFolders()
        }
        .onChange(of: appEnvironment.session?.isAuthenticated == true) { _, isAuthenticated in
            guard isAuthenticated else {
                folders = []
                return
            }
            Task {
                await loadFolders()
            }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch themePreference.lowercased() {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    private func togglePin(for thread: ChatThreadRecord) {
        if shouldBlockManagement(for: thread) {
            managementNotice = "Finish or leave the active conversation before changing its management state."
            return
        }

        let nextPinned = !thread.isPinned
        withAnimation(DS.Motion.quickSpring) {
            persistence.updateLocalThread(remoteId: thread.remoteId, isPinned: nextPinned)
        }

        Task {
            do {
                try await appEnvironment.chatService.updateChat(id: thread.remoteId, title: nil, folderId: nil, isPinned: nextPinned)
                await appEnvironment.refreshConversations()
            } catch {
                await MainActor.run {
                    withAnimation(DS.Motion.quickSpring) {
                        persistence.updateLocalThread(remoteId: thread.remoteId, isPinned: thread.isPinned)
                    }
                    managementNotice = "Could not update pin status right now."
                }
            }
        }
    }

    private func renameConversation(_ thread: ChatThreadRecord, to newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            managementNotice = "Conversation title cannot be empty."
            return
        }

        if shouldBlockManagement(for: thread) {
            managementNotice = "Finish or leave the active conversation before renaming it."
            return
        }

        withAnimation(DS.Motion.quickSpring) {
            persistence.updateLocalThread(remoteId: thread.remoteId, title: trimmed)
        }

        Task {
            do {
                try await appEnvironment.chatService.renameChat(id: thread.remoteId, title: trimmed)
                await appEnvironment.refreshConversations()
            } catch {
                await MainActor.run {
                    withAnimation(DS.Motion.quickSpring) {
                        persistence.updateLocalThread(remoteId: thread.remoteId, title: thread.title)
                    }
                    managementNotice = "Could not rename conversation right now."
                }
            }
        }
    }

    private func removeConversation(_ thread: ChatThreadRecord) {
        if appEnvironment.selectedThreadId == thread.remoteId {
            appEnvironment.selectedThreadId = nil
        }

        withAnimation(DS.Motion.spring) {
            persistence.deleteThread(remoteId: thread.remoteId)
        }

        Task {
            do {
                try await appEnvironment.chatService.deleteChat(id: thread.remoteId)
                await appEnvironment.refreshConversations()
            } catch {
                await MainActor.run {
                    managementNotice = "Could not remove conversation right now."
                }
                await appEnvironment.refreshConversations()
            }
        }
    }

    private func shouldBlockManagement(for thread: ChatThreadRecord) -> Bool {
        appEnvironment.selectedThreadId == thread.remoteId
    }

    private func loadFolders() async {
        guard appEnvironment.session?.isAuthenticated == true, !appEnvironment.isAuthenticating else {
            folders = []
            return
        }

        do {
            let fetchedFolders = try await appEnvironment.chatService.fetchFolders()
            withAnimation(DS.Motion.quickSpring) {
                folders = fetchedFolders.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            }
        } catch {
            if AppConfig.enableNetworkDebugLogs {
                print("TAI folder refresh failed: \(error)")
            }
        }
    }

    private func createFolder(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            managementNotice = "Workspace name cannot be empty."
            return
        }
        guard appEnvironment.session?.isAuthenticated == true else {
            managementNotice = "Sign in to create workspaces."
            return
        }

        Task {
            do {
                let folder = try await appEnvironment.chatService.createFolder(name: trimmed)
                await MainActor.run {
                    withAnimation(DS.Motion.quickSpring) {
                        folders.removeAll { $0.id == folder.id }
                        folders.append(folder)
                        folders.sort {
                            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    managementNotice = "Could not create workspace right now."
                }
            }
        }
    }

    private func deleteProject(_ folder: ChatFolderSummary, deleteChats: Bool) {
        guard appEnvironment.session?.isAuthenticated == true else { return }

        Task {
            do {
                // If deleteChats, delete all conversations in this project first
                if deleteChats {
                    let threadsInFolder = PersistenceController.shared.threads.filter { $0.folderId == folder.id }
                    for thread in threadsInFolder {
                        try? await appEnvironment.chatService.deleteChat(id: thread.remoteId)
                        await MainActor.run {
                            PersistenceController.shared.deleteThread(remoteId: thread.remoteId)
                        }
                    }
                }

                // Delete the folder (backend ungroups remaining chats)
                try await appEnvironment.chatService.deleteFolder(id: folder.id)
                await MainActor.run {
                    withAnimation(DS.Motion.quickSpring) {
                        folders.removeAll { $0.id == folder.id }
                    }
                }
            } catch {
                await MainActor.run {
                    managementNotice = "Could not delete project."
                }
            }
        }
    }

    private func assignConversation(_ thread: ChatThreadRecord, to folderId: String) {
        guard thread.folderId != folderId else { return }

        if shouldBlockManagement(for: thread) {
            managementNotice = "Finish or leave the active conversation before moving it."
            return
        }

        let previousFolderId = thread.folderId
        withAnimation(DS.Motion.quickSpring) {
            persistence.updateLocalThreadFolder(remoteId: thread.remoteId, folderId: folderId)
        }

        Task {
            do {
                try await appEnvironment.chatService.updateChat(id: thread.remoteId, title: nil, folderId: folderId, isPinned: nil)
                await appEnvironment.refreshConversations()
                await loadFolders()
            } catch {
                await MainActor.run {
                    withAnimation(DS.Motion.quickSpring) {
                        persistence.updateLocalThreadFolder(remoteId: thread.remoteId, folderId: previousFolderId)
                    }
                    managementNotice = "Could not move conversation right now."
                }
            }
        }
    }
}
