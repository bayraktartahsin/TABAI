import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = HistoryViewModel(chatService: MockChatService())
    @State private var renameTarget: HistoryViewModel.Thread?
    @State private var renameText: String = ""
    @State private var deleteTarget: HistoryViewModel.Thread?
    @State private var newFolderName: String = ""
    @State private var showCreateFolder: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            header

            searchField

             if viewModel.folders.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.folders) { folder in
                            Text(folder.name)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(DS.Colors.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(DS.Colors.fieldBackground)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            List {
                ForEach(viewModel.filteredThreads) { thread in
                    HistoryRow(
                        thread: thread,
                        isActive: appEnvironment.selectedThreadId == thread.id
                    ) {
                        viewModel.togglePin(thread)
                    } onOpen: {
                        withAnimation(DS.Motion.spring) {
                            appEnvironment.selectedThreadId = thread.id
                            appEnvironment.selectedTab = .chat
                        }
                    } onRename: {
                        renameTarget = thread
                        renameText = thread.title
                    } onDelete: {
                        deleteTarget = thread
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .animation(DS.Motion.spring, value: viewModel.filteredThreads)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Layout.horizontalPadding)
        .taiFullscreen {
            GradientBackground()
        }
        .sheet(item: $renameTarget, onDismiss: {
            renameText = ""
        }) { thread in
            RenameChatSheet(
                title: $renameText,
                currentTitle: thread.title,
                onCancel: {
                    renameTarget = nil
                    renameText = ""
                },
                onSave: {
                    let next = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard next.isEmpty == false else { return }
                    viewModel.rename(thread, title: next)
                    renameTarget = nil
                    renameText = ""
                }
            )
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
            .onAppear {
                renameText = thread.title
            }
        }
        .alert("Delete conversation?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let thread = deleteTarget {
                    viewModel.delete(thread)
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("This chat will be removed from your history.")
        }
        .alert("New Folder", isPresented: $showCreateFolder) {
            TextField("Folder name", text: $newFolderName)
            Button("Create") {
                let next = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                if next.isEmpty == false {
                    viewModel.createFolder(name: next)
                }
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
        }
        .task {
            viewModel.configure(chatService: appEnvironment.chatService)
            await viewModel.refresh()
        }
    }

    private var header: some View {
        HStack {
            Text(t("history.title", fallback: "History"))
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Button {
                appEnvironment.selectedThreadId = nil
                appEnvironment.selectedTab = .chat
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Button {
                showCreateFolder = true
            } label: {
                Image(systemName: "folder.badge.plus")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DS.Colors.textSecondary)
            TextField(t("history.search", fallback: "Search"), text: $viewModel.searchText)
                .textInputAutocapitalization(.sentences)
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DS.Colors.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous)
                .stroke(DS.Colors.glassStroke, lineWidth: 1)
        )
    }
}

private struct HistoryRow: View {
    let thread: HistoryViewModel.Thread
    let isActive: Bool
    let onPin: () -> Void
    let onOpen: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: thread.isPinned ? "pin.fill" : "pin")
                .foregroundStyle(thread.isPinned ? DS.Colors.accent : DS.Colors.textSecondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(thread.title)
                    .font(DS.Typography.subtitle)
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(thread.lastMessage)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(2)
                if let modelDisplayName = thread.modelDisplayName {
                    Text(modelDisplayName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DS.Colors.fieldBackground)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .padding(14)
        .background(isActive ? DS.Colors.accent.opacity(0.16) : DS.Colors.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous)
                .stroke(isActive ? DS.Colors.accent.opacity(0.45) : DS.Colors.glassStroke, lineWidth: 1)
        )
        .scaleEffect(isActive ? 1.01 : 1)
        .onTapGesture(perform: onOpen)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onPin) {
                Label(thread.isPinned ? "Unpin" : "Pin", systemImage: thread.isPinned ? "pin.slash.fill" : "pin.fill")
            }
                .tint(.yellow)
            Button(action: onRename) {
                Label("Rename", systemImage: "pencil")
            }
                .tint(.blue)
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .animation(DS.Motion.quickSpring, value: thread.isPinned)
        .animation(DS.Motion.quickSpring, value: isActive)
    }
}

private struct RenameChatSheet: View {
    @Binding var title: String
    let currentTitle: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Rename chat")
                    .font(DS.Typography.subtitle)
                    .foregroundStyle(DS.Colors.textPrimary)

                TextField(currentTitle, text: $title)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous)
                            .stroke(DS.Colors.glassStroke, lineWidth: 1)
                    )

                Spacer()
            }
            .padding(24)
            .background(GradientBackground())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
