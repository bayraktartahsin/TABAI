import Foundation

final class FalAIService: FalAIServiceProtocol {
    private let client: TABAIClient

    init(client: TABAIClient) {
        self.client = client
    }

    func submitImage(
        prompt: String,
        negativePrompt: String?,
        modelId: String,
        chatId: String?,
        imageSize: String?,
        numImages: Int?,
        style: String?
    ) async throws -> GenerationSubmitResponse {
        let url = client.baseURL.appendingPathComponent("api/generate/image")
        let body = GenerationSubmitRequest(
            prompt: prompt,
            negativePrompt: negativePrompt,
            modelId: modelId,
            chatId: chatId,
            imageSize: imageSize,
            numImages: numImages,
            style: style,
            duration: nil,
            resolution: nil,
            imageUrl: nil
        )
        let data = try JSONEncoder().encode(body)
        return try await client.requestJSON(method: "POST", url: url, body: data)
    }

    func submitVideo(
        prompt: String,
        negativePrompt: String?,
        modelId: String,
        chatId: String?,
        duration: String?,
        resolution: String?,
        imageUrl: String?
    ) async throws -> GenerationSubmitResponse {
        let url = client.baseURL.appendingPathComponent("api/generate/video")
        let body = GenerationSubmitRequest(
            prompt: prompt,
            negativePrompt: negativePrompt,
            modelId: modelId,
            chatId: chatId,
            imageSize: nil,
            numImages: nil,
            style: nil,
            duration: duration,
            resolution: resolution,
            imageUrl: imageUrl
        )
        let data = try JSONEncoder().encode(body)
        return try await client.requestJSON(method: "POST", url: url, body: data)
    }

    func checkStatus(generationId: String) async throws -> GenerationStatusResponse {
        let url = client.baseURL.appendingPathComponent("api/generate/status/\(generationId)")
        return try await client.requestJSON(method: "GET", url: url)
    }

    func getResult(generationId: String) async throws -> GenerationRecord {
        let url = client.baseURL.appendingPathComponent("api/generate/\(generationId)")
        return try await client.requestJSON(method: "GET", url: url)
    }

    func getHistory(limit: Int = 50, offset: Int = 0) async throws -> [GenerationRecord] {
        var components = URLComponents(url: client.baseURL.appendingPathComponent("api/generate/history"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
        ]
        let response: GenerationHistoryResponse = try await client.requestJSON(method: "GET", url: components.url!)
        return response.generations
    }

    func cancel(generationId: String) async throws {
        let url = client.baseURL.appendingPathComponent("api/generate/\(generationId)")
        let (_, response) = try await client.requestRaw(method: "DELETE", url: url)
        if response.statusCode >= 400 {
            throw TABAIError.invalidResponse
        }
    }
}
