import Foundation
import Combine
import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    struct Thread: Identifiable, Equatable {
        let id: String
        var title: String
        var lastMessage: String
        var date: Date
        var isPinned: Bool
        var modelDisplayName: String?
        var folderId: String?
    }

    struct Folder: Identifiable, Equatable {
        let id: String
        var name: String
    }

    @Published var searchText: String = ""
    @Published private(set) var threads: [Thread] = []
    @Published private(set) var folders: [Folder] = []

    private var chatService: ChatServiceProtocol
    private let persistence: PersistenceController

    init(chatService: ChatServiceProtocol, persistence: PersistenceController? = nil) {
        self.chatService = chatService
        self.persistence = persistence ?? PersistenceController.shared
        loadFromCache()
    }

    var filteredThreads: [Thread] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = threads.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.date > rhs.date
        }
        guard !query.isEmpty else { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.lastMessage.localizedCaseInsensitiveContains(query) }
    }

    func configure(chatService: ChatServiceProtocol) {
        self.chatService = chatService
    }

    func refresh() async {
        do {
            async let remoteThreads = chatService.fetchChats()
            async let remoteFolders = chatService.fetchFolders()
            let (threads, fetchedFolders) = try await (remoteThreads, remoteFolders)
            persistence.upsertThreads(threads)
            withAnimation(DS.Motion.spring) {
                folders = fetchedFolders.map { Folder(id: $0.id, name: $0.name) }
                loadFromCache()
            }
        } catch {
            withAnimation(DS.Motion.spring) {
                loadFromCache()
            }
        }
    }

    func togglePin(_ thread: Thread) {
        Task {
            let nextPinned = !thread.isPinned
            withAnimation(DS.Motion.quickSpring) {
                persistence.updateLocalThread(remoteId: thread.id, isPinned: nextPinned)
                loadFromCache()
            }
            do {
                try await chatService.updateChat(id: thread.id, title: nil, folderId: nil, isPinned: nextPinned)
                await refresh()
            } catch {
                withAnimation(DS.Motion.quickSpring) {
                    persistence.updateLocalThread(remoteId: thread.id, isPinned: thread.isPinned)
                    loadFromCache()
                }
            }
        }
    }

    func rename(_ thread: Thread, title: String) {
        Task {
            withAnimation(DS.Motion.spring) {
                persistence.updateLocalThread(remoteId: thread.id, title: title)
                loadFromCache()
            }
            do {
                try await chatService.renameChat(id: thread.id, title: title)
                await refresh()
            } catch {
                withAnimation(DS.Motion.spring) {
                    persistence.updateLocalThread(remoteId: thread.id, title: thread.title)
                    loadFromCache()
                }
            }
        }
    }

    func delete(_ thread: Thread) {
        Task {
            withAnimation(DS.Motion.spring) {
                persistence.deleteThread(remoteId: thread.id)
                loadFromCache()
            }
            do {
                try await chatService.deleteChat(id: thread.id)
                await refresh()
            } catch {
                await refresh()
            }
        }
    }

    func createFolder(name: String) {
        Task {
                guard let folder = try? await chatService.createFolder(name: name) else { return }
            withAnimation(DS.Motion.spring) {
                folders.append(Folder(id: folder.id, name: folder.name))
                folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
    }

    private func loadFromCache() {
        threads = persistence.threads.map {
            Thread(
                id: $0.remoteId,
                title: $0.title,
                lastMessage: $0.lastMessage,
                date: $0.updatedAt,
                isPinned: $0.isPinned,
                modelDisplayName: $0.modelDisplayName,
                folderId: $0.folderId
            )
        }
    }
}
