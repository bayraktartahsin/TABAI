import SwiftUI
import UIKit

struct ConversationDrawerView: View {
    let conversations: [ChatThreadRecord]
    let selectedThreadId: String?
    let onSelectConversation: (String) -> Void
    let accountEmail: String?
    let planLabel: String
    let onTogglePin: (ChatThreadRecord) -> Void
    let onRenameConversation: (ChatThreadRecord, String) -> Void
    let onDeleteConversation: (ChatThreadRecord) -> Void
    let onNewChat: () -> Void
    let onSettings: () -> Void
    let onSubscription: () -> Void
    let folders: [ChatFolderSummary]
    let onCreateFolder: (String) -> Void
    let onDeleteFolder: (ChatFolderSummary, Bool) -> Void  // (folder, deleteChats)
    let onAssignConversationToFolder: (ChatThreadRecord, String) -> Void

    @State private var renameTarget: ChatThreadRecord?
    @State private var renameText: String = ""
    @State private var deleteTarget: ChatThreadRecord?
    @State private var searchText: String = ""
    @State private var showCreateFolder: Bool = false
    @State private var newFolderName: String = ""
    @State private var projectToDelete: ChatFolderSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: New Thread + New Project buttons
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Button {
                        Haptics.impact(.light)
                        onNewChat()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text(L("New Thread"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(DS.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(newThreadBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(newThreadBorder, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(DrawerPressButtonStyle())

                    Button {
                        Haptics.impact(.light)
                        showCreateFolder = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 13, weight: .medium))
                            Text(L("Project"))
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(DS.Colors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(newThreadBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(newThreadBorder, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(DrawerPressButtonStyle())
                }

                // Search
                if !conversations.isEmpty {
                    DrawerSearchField(text: $searchText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Conversation list
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if sortedConversations.isEmpty {
                        DrawerEmptyState(onNewChat: onNewChat)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                    } else if filteredConversations.isEmpty {
                        DrawerNoResultsState(query: searchText) {
                            withAnimation { searchText = "" }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    } else {
                        // Pinned section
                        let pinned = filteredConversations.filter(\.isPinned)
                        if !pinned.isEmpty {
                            drawerSection(title: L("Pinned"), threads: pinned)
                        }

                        // Project sections (collapsible)
                        if !displayedFolders.isEmpty {
                            projectsHeader
                        }
                        ForEach(displayedFolders) { folder in
                            let folderThreads = conversations(in: folder).filter { !$0.isPinned }
                            ProjectSection(
                                folder: folder,
                                threads: folderThreads,
                                selectedThreadId: selectedThreadId,
                                onSelect: { threadId in
                                    Haptics.impact(.light)
                                    onSelectConversation(threadId)
                                },
                                onContextAction: contextAction,
                                onDeleteProject: {
                                    projectToDelete = folder
                                }
                            )
                        }

                        // Date-grouped ungrouped conversations
                        let ungrouped = ungroupedConversations.filter { !$0.isPinned }
                        let grouped = groupByDate(ungrouped)

                        ForEach(grouped, id: \.title) { group in
                            drawerSection(title: group.title, threads: group.threads)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .animation(DS.Motion.quickSpring, value: searchText)

            Spacer(minLength: 0)

            // Bottom: account bar
            drawerBottomBar
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(item: $renameTarget) { thread in
            DrawerRenameSheet(
                title: $renameText,
                currentTitle: thread.title,
                onCancel: { renameTarget = nil; renameText = "" },
                onSave: {
                    let next = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !next.isEmpty else { return }
                    onRenameConversation(thread, next)
                    renameTarget = nil; renameText = ""
                }
            )
            .presentationDetents([.height(200)])
            .taiSheetChrome()
            .onAppear { renameText = thread.title }
        }
        .alert("Delete conversation?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let thread = deleteTarget { onDeleteConversation(thread) }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        }
        .confirmationDialog(
            "Delete Project?",
            isPresented: Binding(
                get: { projectToDelete != nil },
                set: { if !$0 { projectToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Keep Chats, Delete Project") {
                if let project = projectToDelete {
                    Haptics.impact(.light)
                    onDeleteFolder(project, false)
                }
                projectToDelete = nil
            }
            Button("Delete Project & All Chats", role: .destructive) {
                if let project = projectToDelete {
                    Haptics.impact(.rigid)
                    onDeleteFolder(project, true)
                }
                projectToDelete = nil
            }
            Button("Cancel", role: .cancel) { projectToDelete = nil }
        } message: {
            if let project = projectToDelete {
                let count = conversations(in: project).count
                Text("\"\(project.name)\" has \(count) conversation\(count == 1 ? "" : "s"). What would you like to do?")
            }
        }
        .alert("New Project", isPresented: $showCreateFolder) {
            TextField("Project name", text: $newFolderName)
            Button("Create") {
                let next = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !next.isEmpty { onCreateFolder(next) }
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) { newFolderName = "" }
        }
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func drawerSection(title: String, threads: [ChatThreadRecord], isFolder: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                if isFolder {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.7))
                    .textCase(.none)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 4)

            ForEach(threads) { thread in
                drawerRow(thread)
            }
        }
    }

    // MARK: - Row

    private func drawerRow(_ thread: ChatThreadRecord) -> some View {
        let isSelected = selectedThreadId == thread.remoteId

        return Button {
            Haptics.impact(.light)
            onSelectConversation(thread.remoteId)
        } label: {
            HStack(spacing: 10) {
                Text(thread.title.isEmpty ? "Untitled" : thread.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? DS.Colors.textPrimary : DS.Colors.textPrimary.opacity(0.85))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if thread.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isSelected ? selectedRowBackground : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(DrawerPressButtonStyle())
        .padding(.horizontal, 8)
        .contextMenu {
            Button { onTogglePin(thread) } label: {
                Label(thread.isPinned ? "Unpin" : "Pin", systemImage: thread.isPinned ? "pin.slash" : "pin")
            }
            Button { renameTarget = thread; renameText = thread.title } label: {
                Label("Rename", systemImage: "pencil")
            }
            if !folders.isEmpty {
                Menu {
                    ForEach(folders.filter { $0.id != thread.folderId }) { folder in
                        Button(folder.name) { onAssignConversationToFolder(thread, folder.id) }
                    }
                } label: {
                    Label("Move to Project", systemImage: "folder")
                }
            }
            Divider()
            Button(role: .destructive) { deleteTarget = thread } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Projects Header

    private var projectsHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DS.Colors.accent.opacity(0.6))
            Text("Projects")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DS.Colors.textSecondary.opacity(0.7))
            Spacer()
            Button {
                Haptics.impact(.light)
                showCreateFolder = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 2)
    }

    private func contextAction(thread: ChatThreadRecord, action: DrawerContextAction) {
        switch action {
        case .pin: onTogglePin(thread)
        case .rename: renameTarget = thread; renameText = thread.title
        case .delete: deleteTarget = thread
        case .moveToProject(let folderId): onAssignConversationToFolder(thread, folderId)
        }
    }

    // MARK: - Bottom Bar

    private var drawerBottomBar: some View {
        VStack(spacing: 8) {
            Divider()
                .foregroundStyle(DS.Colors.textSecondary.opacity(0.1))

            HStack(spacing: 12) {
                // Avatar + email
                Button {
                    Haptics.impact(.light)
                    onSettings()
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(avatarBackground)
                                .frame(width: 30, height: 30)
                            Text(avatarInitials)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DS.Colors.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(displayEmail)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(DS.Colors.textPrimary)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Plan badge
                Button {
                    Haptics.impact(.light)
                    onSubscription()
                } label: {
                    Text(planLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DS.Colors.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Settings gear
                Button {
                    Haptics.impact(.light)
                    onSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Date Grouping

    private struct DateGroup: Identifiable {
        let title: String
        let threads: [ChatThreadRecord]
        var id: String { title }
    }

    private func groupByDate(_ threads: [ChatThreadRecord]) -> [DateGroup] {
        let calendar = Calendar.current
        let now = Date()

        var today: [ChatThreadRecord] = []
        var yesterday: [ChatThreadRecord] = []
        var thisWeek: [ChatThreadRecord] = []
        var older: [ChatThreadRecord] = []

        for thread in threads {
            if calendar.isDateInToday(thread.updatedAt) {
                today.append(thread)
            } else if calendar.isDateInYesterday(thread.updatedAt) {
                yesterday.append(thread)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                      thread.updatedAt >= weekAgo {
                thisWeek.append(thread)
            } else {
                older.append(thread)
            }
        }

        var groups: [DateGroup] = []
        if !today.isEmpty { groups.append(DateGroup(title: L("Today"), threads: today)) }
        if !yesterday.isEmpty { groups.append(DateGroup(title: L("Yesterday"), threads: yesterday)) }
        if !thisWeek.isEmpty { groups.append(DateGroup(title: "Previous 7 Days", threads: thisWeek)) }
        if !older.isEmpty { groups.append(DateGroup(title: L("Older"), threads: older)) }
        return groups
    }

    // MARK: - Data

    private var sortedConversations: [ChatThreadRecord] {
        conversations.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private var filteredConversations: [ChatThreadRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sortedConversations }
        return sortedConversations.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private var displayedFolders: [ChatFolderSummary] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return folders }
        return folders.filter { !conversations(in: $0).isEmpty }
    }

    private var knownFolderIds: Set<String> {
        Set(folders.map(\.id))
    }

    private var ungroupedConversations: [ChatThreadRecord] {
        filteredConversations.filter { thread in
            guard let folderId = thread.folderId else { return true }
            return !knownFolderIds.contains(folderId)
        }
    }

    private func conversations(in folder: ChatFolderSummary) -> [ChatThreadRecord] {
        filteredConversations.filter { $0.folderId == folder.id }
    }

    // MARK: - Appearance

    private var displayEmail: String {
        let trimmed = accountEmail?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Not signed in" : trimmed
    }

    private var avatarInitials: String {
        guard let email = accountEmail, !email.isEmpty else { return "?" }
        return String(email.prefix(1)).uppercased()
    }

    private var avatarBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.06)
        })
    }

    private var selectedRowBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.05)
        })
    }

    private var newThreadBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.06)
                : UIColor.black.withAlphaComponent(0.03)
        })
    }

    private var newThreadBorder: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.1)
                : UIColor.black.withAlphaComponent(0.08)
        })
    }
}

// MARK: - Context Action

enum DrawerContextAction {
    case pin
    case rename
    case delete
    case moveToProject(String)
}

// MARK: - Collapsible Project Section

private struct ProjectSection: View {
    let folder: ChatFolderSummary
    let threads: [ChatThreadRecord]
    let selectedThreadId: String?
    let onSelect: (String) -> Void
    let onContextAction: (ChatThreadRecord, DrawerContextAction) -> Void
    let onDeleteProject: () -> Void
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Project header (tap to collapse, long-press for options)
            Button {
                withAnimation(DS.Motion.quickSpring) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
                        .frame(width: 12)

                    Circle()
                        .fill(projectColor)
                        .frame(width: 8, height: 8)

                    Text(folder.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Colors.textPrimary.opacity(0.8))

                    Text("\(threads.count)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    onDeleteProject()
                } label: {
                    Label("Delete Project", systemImage: "trash")
                }
            }

            // Threads (collapsible)
            if isExpanded {
                ForEach(threads) { thread in
                    let isSelected = selectedThreadId == thread.remoteId
                    Button {
                        onSelect(thread.remoteId)
                    } label: {
                        HStack(spacing: 8) {
                            Text(thread.title.isEmpty ? "Untitled" : thread.title)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? DS.Colors.textPrimary : DS.Colors.textPrimary.opacity(0.75))
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            if thread.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .padding(.leading, 20) // indent under project
                        .background(isSelected ? selectedBg : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(DrawerPressButtonStyle())
                    .padding(.horizontal, 8)
                    .contextMenu {
                        Button { onContextAction(thread, .pin) } label: {
                            Label(thread.isPinned ? "Unpin" : "Pin", systemImage: thread.isPinned ? "pin.slash" : "pin")
                        }
                        Button { onContextAction(thread, .rename) } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) { onContextAction(thread, .delete) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var projectColor: Color {
        if let colorHex = folder.color, !colorHex.isEmpty {
            return DS.Colors.accent // could parse hex later
        }
        return DS.Colors.accent.opacity(0.7)
    }

    private var selectedBg: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.07)
                : UIColor.black.withAlphaComponent(0.04)
        })
    }
}

// MARK: - Supporting Views

private struct DrawerSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
            TextField("Search", text: $text)
                .font(.system(size: 14))
                .foregroundStyle(DS.Colors.textPrimary)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor.black.withAlphaComponent(0.03)
        }))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DrawerEmptyState: View {
    let onNewChat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No conversations yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)
            Text("Start a new thread to begin.")
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.textSecondary.opacity(0.7))
        }
    }
}

private struct DrawerNoResultsState: View {
    let query: String
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No results for \"\(query)\"")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)
            Button("Clear search") { onClear() }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.accent)
        }
    }
}

private struct DrawerRenameSheet: View {
    @Binding var title: String
    let currentTitle: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rename")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Colors.textPrimary)

            TextField(currentTitle, text: $title)
                .font(.system(size: 15))
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(DS.Colors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack {
                Button("Cancel") { onCancel() }
                    .foregroundStyle(DS.Colors.textSecondary)
                Spacer()
                Button("Save") { onSave() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.accent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .font(.system(size: 15))

            Spacer()
        }
        .padding(20)
    }
}

private struct DrawerPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
