import Foundation
import Combine
import SwiftUI
import PhotosUI

@MainActor
final class VideoGeneratorViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case submitting
        case polling(generationId: String)
        case completed(resultUrl: String)
        case failed(message: String)
    }

    @Published var prompt: String = ""
    @Published var selectedModelId: String = FalModel.videoModels.first?.id ?? ""
    @Published var selectedDuration: String = "5"
    @Published var selectedResolution: String = "720p"
    @Published var useImageToVideo: Bool = false
    @Published var selectedPhoto: PhotosPickerItem?
    @Published private(set) var selectedPhotoData: Data?
    @Published private(set) var state: State = .idle
    @Published private(set) var progressText: String = ""
    @Published private(set) var queuePosition: Int?

    private let service: FalAIServiceProtocol
    private var pollingTask: Task<Void, Never>?

    init(service: FalAIServiceProtocol) {
        self.service = service
    }

    var canGenerate: Bool {
        let hasPrompt = !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPhoto = !useImageToVideo || selectedPhotoData != nil
        return hasPrompt && hasPhoto && state == .idle
    }

    func generate() {
        guard canGenerate else { return }
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

        state = .submitting
        progressText = "Submitting..."

        Task {
            do {
                // If image-to-video, we'd need to upload the image first
                // For now, imageUrl is nil unless we have a URL
                let response = try await service.submitVideo(
                    prompt: trimmedPrompt,
                    negativePrompt: nil,
                    modelId: useImageToVideo ? "fal-ai/kling-video/v2.5/master/image-to-video" : selectedModelId,
                    chatId: nil,
                    duration: selectedDuration,
                    resolution: selectedResolution,
                    imageUrl: nil
                )
                state = .polling(generationId: response.id)
                progressText = "Creating your video..."
                startPolling(generationId: response.id)
            } catch {
                state = .failed(message: error.localizedDescription)
                progressText = ""
            }
        }
    }

    func cancel() {
        pollingTask?.cancel()
        pollingTask = nil
        if case .polling(let id) = state {
            Task { try? await service.cancel(generationId: id) }
        }
        state = .idle
        progressText = ""
    }

    func reset() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
        progressText = ""
        queuePosition = nil
    }

    private func startPolling(generationId: String) {
        pollingTask?.cancel()
        pollingTask = Task {
            var attempts = 0
            while !Task.isCancelled {
                do {
                    let status = try await service.checkStatus(generationId: generationId)
                    queuePosition = status.queuePosition

                    switch status.status {
                    case "completed":
                        if let url = status.resultUrl {
                            state = .completed(resultUrl: url)
                            progressText = ""
                        } else {
                            state = .failed(message: "Generation completed but no result URL.")
                            progressText = ""
                        }
                        return
                    case "failed":
                        state = .failed(message: status.errorMessage ?? "Generation failed.")
                        progressText = ""
                        return
                    case "processing":
                        progressText = "Rendering video..."
                    default:
                        if let pos = status.queuePosition, pos > 0 {
                            progressText = "Queue position: \(pos)"
                        } else {
                            progressText = "Creating your video..."
                        }
                    }
                } catch {
                    if Task.isCancelled { return }
                }

                attempts += 1
                // Videos take longer — poll less frequently
                let delay: UInt64 = attempts < 3 ? 3_000_000_000 : 5_000_000_000
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }
}

extension VideoGeneratorViewModel {
    func loadPhotoData() {
        guard let item = selectedPhoto else {
            selectedPhotoData = nil
            return
        }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                selectedPhotoData = data
            }
        }
    }
}
