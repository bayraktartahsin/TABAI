import Foundation

struct TABAIChatService: ChatServiceProtocol {
    enum Error: Swift.Error {
        case invalidResponse
    }

    let client: TABAIClient

    func fetchChats() async throws -> [ChatThreadSummary] {
        let url = client.baseURL.appendingPathComponent("api/chats")
        let (data, response) = try await client.requestRaw(method: "GET", url: url)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let array = json["chats"] as? [[String: Any]]
        else {
            throw Error.invalidResponse
        }
        return array.compactMap(mapThread(from:))
    }

    func fetchChatDetail(id: String) async throws -> ChatDetail {
        let threadURL = client.baseURL.appendingPathComponent("api/chats")
        let messagesURL = client.baseURL.appendingPathComponent("api/chats/\(id)/messages")

        async let threadsTask = client.requestRaw(method: "GET", url: threadURL)
        async let messagesTask = client.requestRaw(method: "GET", url: messagesURL)

        let ((threadsData, threadsResponse), (messagesData, messagesResponse)) = try await (threadsTask, messagesTask)
        guard threadsResponse.statusCode == 200, messagesResponse.statusCode == 200 else {
            throw Error.invalidResponse
        }

        guard
            let threadsJson = try? JSONSerialization.jsonObject(with: threadsData) as? [String: Any],
            let threadArray = threadsJson["chats"] as? [[String: Any]],
            let threadDict = threadArray.first(where: { ($0["id"] as? String) == id }),
            let messagesJson = try? JSONSerialization.jsonObject(with: messagesData) as? [String: Any],
            let messagesArray = messagesJson["messages"] as? [[String: Any]]
        else {
            throw Error.invalidResponse
        }

        guard let thread = mapThread(from: threadDict) else {
            throw Error.invalidResponse
        }
        let mappedMessages = messagesArray.compactMap { mapMessage(from: $0, fallbackDate: thread.updatedAt) }
        return ChatDetail(thread: thread, messages: mappedMessages)
    }

    func createChat(id: String, title: String, modelId: String?, folderId: String?) async throws -> ChatDetail {
        let url = client.baseURL.appendingPathComponent("api/chats")
        var payload: [String: Any] = ["title": title]
        if let modelId, modelId.isEmpty == false {
            payload["modelId"] = modelId
        }
        if let folderId {
            payload["folderId"] = folderId
        }
        let body = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await client.requestRaw(method: "POST", url: url, body: body)
        guard response.statusCode == 200 || response.statusCode == 201 else {
            throw Error.invalidResponse
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let chatDict = json["chat"] as? [String: Any],
            chatDict["id"] as? String != nil,
            let thread = mapThread(from: chatDict)
        else {
            throw Error.invalidResponse
        }

        return ChatDetail(thread: thread, messages: [])
    }

    func createMessage(chatId: String, role: String, text: String) async throws -> ChatMessageSummary {
        let url = client.baseURL.appendingPathComponent("api/chats/\(chatId)/messages")
        let body = try JSONSerialization.data(withJSONObject: [
            "role": role.uppercased(),
            "content": text
        ])

        let (data, response) = try await client.requestRaw(method: "POST", url: url, body: body)
        guard response.statusCode == 201 || response.statusCode == 200 else {
            throw Error.invalidResponse
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = json["message"] as? [String: Any],
            let mapped = mapMessage(from: message, fallbackDate: Date())
        else {
            throw Error.invalidResponse
        }

        return mapped
    }

    func renameChat(id: String, title: String) async throws {
        try await updateChat(id: id, title: title, folderId: nil, isPinned: nil)
    }

    func updateChat(id: String, title: String?, folderId: String?, isPinned: Bool?) async throws {
        let url = client.baseURL.appendingPathComponent("api/chats/\(id)")
        var payload: [String: Any] = [:]
        if let title {
            payload["title"] = title
        }
        if let folderId {
            payload["folderId"] = folderId
        } else if folderId != nil {
            payload["folderId"] = NSNull()
        }
        if let isPinned {
            payload["isPinned"] = isPinned
        }
        let body = try JSONSerialization.data(withJSONObject: payload)
        let (_, response) = try await client.requestRaw(method: "PATCH", url: url, body: body)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }
    }

    func deleteChat(id: String) async throws {
        let url = client.baseURL.appendingPathComponent("api/chats/\(id)")
        let (_, response) = try await client.requestRaw(method: "DELETE", url: url)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }
    }

    func fetchFolders() async throws -> [ChatFolderSummary] {
        let url = client.baseURL.appendingPathComponent("api/folders")
        let (data, response) = try await client.requestRaw(method: "GET", url: url)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let folders = json["folders"] as? [[String: Any]]
        else {
            throw Error.invalidResponse
        }
        return folders.compactMap { item in
            guard
                let id = item["id"] as? String,
                let name = item["name"] as? String
            else {
                return nil
            }
            return ChatFolderSummary(id: id, name: name, color: item["color"] as? String)
        }
    }

    func createFolder(name: String) async throws -> ChatFolderSummary {
        let url = client.baseURL.appendingPathComponent("api/folders")
        let body = try JSONSerialization.data(withJSONObject: ["name": name])
        let (data, response) = try await client.requestRaw(method: "POST", url: url, body: body)
        guard response.statusCode == 200 || response.statusCode == 201 else {
            throw Error.invalidResponse
        }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let folder = json["folder"] as? [String: Any],
            let id = folder["id"] as? String,
            let resolvedName = folder["name"] as? String
        else {
            throw Error.invalidResponse
        }
        return ChatFolderSummary(id: id, name: resolvedName, color: folder["color"] as? String)
    }

    func deleteFolder(id: String) async throws {
        let url = client.baseURL.appendingPathComponent("api/folders/\(id)")
        let (_, response) = try await client.requestRaw(method: "DELETE", url: url)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }
    }

    func completeChat(model: String, messages: [ChatMessageSummary]) async throws -> String {
        throw Error.invalidResponse
    }

    func streamChat(chatId: String, model: String, messages: [ChatMessageSummary], onToken: @escaping (String) -> Void, onMetadata: ((String) -> Void)? = nil) async throws -> String? {
        let url = client.baseURL.appendingPathComponent("api/chat/stream")
        let payload = try JSONSerialization.data(withJSONObject: [
            "chatId": chatId,
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.text] }
        ])

        var streamError: Swift.Error?
        var capturedMessageId: String?
        
        try await client.streamSSE(url: url, body: payload) { event, data in
            switch event {
            case "token":
                if let decoded = try? JSONDecoder().decode(TABAIStreamTokenEvent.self, from: data) {
                    onToken(decoded.delta)
                }
            case "done":
                if let decoded = try? JSONDecoder().decode(TABAIStreamDoneEvent.self, from: data) {
                    capturedMessageId = decoded.messageId
                }
            case "metadata":
                if let decoded = try? JSONDecoder().decode(TABAIStreamMetadataEvent.self, from: data),
                   let poweredBy = decoded.poweredBy {
                    onMetadata?(poweredBy)
                }
            case "error":
                streamError = Error.invalidResponse
            default:
                break
            }
        }
        
        if streamError != nil {
            throw Error.invalidResponse
        }
        
        return capturedMessageId
    }

    private func mapThread(from item: [String: Any]) -> ChatThreadSummary? {
        guard let id = item["id"] as? String else { return nil }
        let title = (item["title"] as? String) ?? "New Chat"
        let updatedAt = parseDate(item["updatedAt"]) ?? Date()
        let createdAt = parseDate(item["createdAt"]) ?? updatedAt
        let lastMessage = ((item["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        let model = item["model"] as? [String: Any]
        return ChatThreadSummary(
            remoteId: id,
            title: title,
            lastMessage: lastMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isPinned: (item["isPinned"] as? Bool) ?? false,
            modelId: item["modelId"] as? String,
            modelDisplayName: (model?["displayName"] as? String) ?? (model?["name"] as? String),
            folderId: item["folderId"] as? String
        )
    }

    private func mapMessage(from item: [String: Any], fallbackDate: Date) -> ChatMessageSummary? {
        guard
            let id = item["id"] as? String,
            let role = item["role"] as? String,
            let content = item["content"] as? String
        else { return nil }
        let createdAt = parseDate(item["createdAt"]) ?? fallbackDate
        let updatedAt = parseDate(item["updatedAt"]) ?? createdAt
        return ChatMessageSummary(
            remoteId: id,
            role: role.lowercased(),
            text: content,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func parseDate(_ value: Any?) -> Date? {
        if let string = value as? String {
            return ISO8601DateFormatter().date(from: string)
        }
        if let interval = value as? TimeInterval {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }
}
