import Foundation
import Combine
import SwiftUI

@MainActor
final class ImageGeneratorViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case submitting
        case polling(generationId: String)
        case completed(resultUrl: String)
        case failed(message: String)
    }

    @Published var prompt: String = ""
    @Published var negativePrompt: String = ""
    @Published var selectedModelId: String = FalModel.imageModels.first?.id ?? ""
    @Published var selectedSize: ImageSize = .squareHD
    @Published var selectedStyle: ImageStyle = .photo
    @Published private(set) var state: State = .idle
    @Published private(set) var history: [GenerationRecord] = []
    @Published private(set) var progressText: String = ""
    @Published private(set) var queuePosition: Int?
    @Published private(set) var quota: GenerationQuotaSnapshot?
    @Published private(set) var quotaError: String?

    private let service: FalAIServiceProtocol
    private var pollingTask: Task<Void, Never>?

    enum ImageSize: String, CaseIterable {
        case squareHD = "square_hd"
        case square = "square"
        case landscape = "landscape_4_3"
        case wide = "landscape_16_9"
        case portrait = "portrait_4_3"

        var label: String {
            switch self {
            case .squareHD: return "Square HD"
            case .square: return "Square"
            case .landscape: return "4:3"
            case .wide: return "16:9"
            case .portrait: return "Portrait"
            }
        }

        var icon: String {
            switch self {
            case .squareHD, .square: return "square"
            case .landscape, .wide: return "rectangle"
            case .portrait: return "rectangle.portrait"
            }
        }
    }

    enum ImageStyle: String, CaseIterable {
        case photo, art, illustration, threeD = "3d", anime

        var label: String {
            switch self {
            case .photo: return "Photo"
            case .art: return "Art"
            case .illustration: return "Illustration"
            case .threeD: return "3D"
            case .anime: return "Anime"
            }
        }
    }

    init(service: FalAIServiceProtocol) {
        self.service = service
    }

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && state == .idle
    }

    func loadQuota() {
        Task {
            do {
                quota = try await service.fetchQuota()
                quotaError = nil
            } catch {
                quotaError = nil // Non-critical, generate will catch server-side
            }
        }
    }

    func generate() {
        guard canGenerate else { return }

        // Client-side quota pre-check
        if let q = quota {
            if !q.generationEnabled {
                state = .failed(message: "Image generation requires Pro or Power plan.")
                return
            }
            if !q.canGenerateImage {
                if q.images.limitPerDay > 0, q.images.remainingToday == 0 {
                    state = .failed(message: "Daily image limit reached (\(q.images.limitPerDay)/day). Try again tomorrow or upgrade.")
                } else if q.images.limitPerMonth > 0, q.images.remainingThisMonth == 0 {
                    state = .failed(message: "Monthly image limit reached (\(q.images.limitPerMonth)/month). Upgrade for more.")
                } else if q.images.limitPerMonth == 0 {
                    state = .failed(message: "Image generation requires a paid plan. Upgrade to get started.")
                } else {
                    state = .failed(message: "Monthly generation budget exhausted. Upgrade for more.")
                }
                return
            }
        }

        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let neg = negativePrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        state = .submitting
        progressText = "Submitting..."

        Task {
            do {
                let response = try await service.submitImage(
                    prompt: trimmedPrompt,
                    negativePrompt: neg.isEmpty ? nil : neg,
                    modelId: selectedModelId,
                    chatId: nil,
                    imageSize: selectedSize.rawValue,
                    numImages: 1,
                    style: selectedStyle.rawValue
                )
                state = .polling(generationId: response.id)
                progressText = "Creating your image..."
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

    func loadHistory() {
        Task {
            do {
                history = try await service.getHistory(limit: 50, offset: 0)
            } catch {
                // Silently fail — history is non-critical
            }
        }
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
                            loadHistory()
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
                        progressText = "Almost ready..."
                    default:
                        if let pos = status.queuePosition, pos > 0 {
                            progressText = "Queue position: \(pos)"
                        } else {
                            progressText = "Creating your image..."
                        }
                    }
                } catch {
                    if Task.isCancelled { return }
                }

                attempts += 1
                let delay: UInt64 = attempts < 5 ? 1_500_000_000 : 3_000_000_000
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }
}
