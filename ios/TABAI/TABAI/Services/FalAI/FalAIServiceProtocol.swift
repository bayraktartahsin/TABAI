import Foundation

protocol FalAIServiceProtocol {
    func submitImage(prompt: String, negativePrompt: String?, modelId: String, chatId: String?, imageSize: String?, numImages: Int?, style: String?) async throws -> GenerationSubmitResponse
    func submitVideo(prompt: String, negativePrompt: String?, modelId: String, chatId: String?, duration: String?, resolution: String?, imageUrl: String?) async throws -> GenerationSubmitResponse
    func checkStatus(generationId: String) async throws -> GenerationStatusResponse
    func getResult(generationId: String) async throws -> GenerationRecord
    func getHistory(limit: Int, offset: Int) async throws -> [GenerationRecord]
    func cancel(generationId: String) async throws
}
