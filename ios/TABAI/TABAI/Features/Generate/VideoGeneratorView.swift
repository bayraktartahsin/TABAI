import SwiftUI
import PhotosUI

struct VideoGeneratorView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel: VideoGeneratorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPromptFocused: Bool

    init(service: FalAIServiceProtocol) {
        _viewModel = StateObject(wrappedValue: VideoGeneratorViewModel(service: service))
    }

    private var accessibleModels: [FalModel] {
        let videoModels = FalModel.accessibleModels(for: appEnvironment.effectiveCurrentPlanTier, type: .video)
        let i2vModels = FalModel.accessibleModels(for: appEnvironment.effectiveCurrentPlanTier, type: .imageToVideo)
        return videoModels + i2vModels
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    promptSection
                    modeSelector
                    durationSelector
                    resolutionSelector
                    modelSelector
                    generateButton
                    resultSection
                }
                .padding(.horizontal, DS.Layout.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [DS.Colors.backgroundTop, DS.Colors.backgroundBottom],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Generate Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $viewModel.prompt)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 140)
                .padding(12)
                .background(DS.Colors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous)
                        .stroke(DS.Colors.glassStroke, lineWidth: 0.5)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.prompt.isEmpty {
                        Text("Describe the video you want to create...")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                            .padding(.top, 20)
                            .padding(.leading, 16)
                            .allowsHitTesting(false)
                    }
                }
                .focused($isPromptFocused)
        }
    }

    // MARK: - Mode (Text-to-Video vs Image-to-Video)

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mode")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)

            HStack(spacing: 8) {
                chipButton("Text to Video", icon: "text.below.photo", selected: !viewModel.useImageToVideo) {
                    viewModel.useImageToVideo = false
                }
                chipButton("Animate Photo", icon: "photo.badge.arrow.down", selected: viewModel.useImageToVideo) {
                    viewModel.useImageToVideo = true
                }
            }

            if viewModel.useImageToVideo {
                PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 14))
                        Text(viewModel.selectedPhotoData != nil ? "Photo selected" : "Choose a photo")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(DS.Colors.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Duration

    private var durationSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)

            HStack(spacing: 8) {
                ForEach(["3", "5", "10"], id: \.self) { dur in
                    chipButton("\(dur)s", selected: viewModel.selectedDuration == dur) {
                        viewModel.selectedDuration = dur
                    }
                }
            }
        }
    }

    // MARK: - Resolution

    private var resolutionSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resolution")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)

            HStack(spacing: 8) {
                chipButton("720p", selected: viewModel.selectedResolution == "720p") {
                    viewModel.selectedResolution = "720p"
                }
                chipButton("1080p", selected: viewModel.selectedResolution == "1080p") {
                    viewModel.selectedResolution = "1080p"
                }
            }
        }
    }

    // MARK: - Model

    private var modelSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)

            if accessibleModels.isEmpty {
                Text("Upgrade to Pro to generate videos.")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(accessibleModels) { model in
                            chipButton(model.displayName, selected: viewModel.selectedModelId == model.id) {
                                viewModel.selectedModelId = model.id
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Generate

    private var generateButton: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Button {
                    Haptics.impact(.medium)
                    isPromptFocused = false
                    viewModel.generate()
                } label: {
                    Text("Generate Video")
                        .font(DS.Typography.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.canGenerate ? DS.Colors.accent : DS.Colors.textSecondary.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
                }
                .disabled(!viewModel.canGenerate)

            case .submitting, .polling:
                GenerationProgressView(
                    text: viewModel.progressText,
                    queuePosition: viewModel.queuePosition,
                    onCancel: { viewModel.cancel() }
                )

            case .completed:
                Button {
                    Haptics.impact(.light)
                    viewModel.reset()
                } label: {
                    Label("Generate Another", systemImage: "sparkles")
                        .font(DS.Typography.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(DS.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
                }

            case .failed(let message):
                VStack(spacing: 8) {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    Button {
                        viewModel.reset()
                    } label: {
                        Text("Try Again")
                            .font(DS.Typography.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(DS.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
                    }
                }
            }
        }
    }

    // MARK: - Result

    private var resultSection: some View {
        Group {
            if case .completed(let url) = viewModel.state {
                VideoResultCard(resultUrl: url, prompt: viewModel.prompt)
            }
        }
    }

    // MARK: - Chip

    private func chipButton(_ label: String, icon: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? DS.Colors.accent.opacity(0.2) : DS.Colors.fieldBackground)
            .foregroundStyle(selected ? DS.Colors.accent : DS.Colors.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(selected ? DS.Colors.accent.opacity(0.5) : DS.Colors.glassStroke, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
