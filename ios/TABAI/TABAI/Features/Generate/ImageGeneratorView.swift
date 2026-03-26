import SwiftUI

struct ImageGeneratorView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel: ImageGeneratorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPromptFocused: Bool

    init(service: FalAIServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ImageGeneratorViewModel(service: service))
    }

    private var accessibleModels: [FalModel] {
        FalModel.accessibleModels(for: appEnvironment.effectiveCurrentPlanTier, type: .image)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    quotaBadge
                    promptSection
                    styleSelector
                    sizeSelector
                    modelSelector
                    generateButton
                    resultSection
                    historySection
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
            .navigationTitle("Generate Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            .onAppear {
                viewModel.loadHistory()
                viewModel.loadQuota()
            }
        }
    }

    // MARK: - Quota Badge

    private var quotaBadge: some View {
        Group {
            if let q = viewModel.quota {
                if !q.generationEnabled {
                    upgradeRequiredBanner
                } else {
                    HStack(spacing: 16) {
                        quotaStat(icon: "photo", used: q.images.usedThisMonth, limit: q.images.limitPerMonth, label: "images")
                        Divider().frame(height: 16)
                        quotaStat(icon: "gauge", used: q.monthlyUnits.used, limit: q.monthlyUnits.limit, label: "budget",
                                  percentUsed: q.monthlyUnits.percentUsed)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DS.Colors.glassStroke, lineWidth: 0.5)
                    )
                }
            }
        }
    }

    private func quotaStat(icon: String, used: Int, limit: Int, label: String, percentUsed: Double? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(usageColor(used: used, limit: limit))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(used)/\(limit)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }

    private func usageColor(used: Int, limit: Int) -> Color {
        guard limit > 0 else { return .red }
        let ratio = Double(used) / Double(limit)
        if ratio >= 0.9 { return .red }
        if ratio >= 0.7 { return .orange }
        return DS.Colors.accent
    }

    private var upgradeRequiredBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Pro plan required")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("Image generation is available on Pro and Power plans")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            Spacer()
            Button {
                appEnvironment.selectedTab = .subscriptions
                dismiss()
            } label: {
                Text("Upgrade")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 0.5)
                )
        )
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
                        Text("Describe what you want to create...")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                            .padding(.top, 20)
                            .padding(.leading, 16)
                            .allowsHitTesting(false)
                    }
                }
                .focused($isPromptFocused)

            DisclosureGroup {
                TextEditor(text: $viewModel.negativePrompt)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(height: 50)
                    .padding(12)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
            } label: {
                Text("Negative prompt")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .tint(DS.Colors.textSecondary)
        }
    }

    // MARK: - Style

    private var styleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Style")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ImageGeneratorViewModel.ImageStyle.allCases, id: \.self) { style in
                        chipButton(style.label, selected: viewModel.selectedStyle == style) {
                            viewModel.selectedStyle = style
                        }
                    }
                }
            }
        }
    }

    // MARK: - Size

    private var sizeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Size")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ImageGeneratorViewModel.ImageSize.allCases, id: \.self) { size in
                        chipButton(size.label, icon: size.icon, selected: viewModel.selectedSize == size) {
                            viewModel.selectedSize = size
                        }
                    }
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
                Text("Upgrade your plan to generate images.")
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

    // MARK: - Generate Button

    private var generateButton: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Button {
                    Haptics.impact(.medium)
                    isPromptFocused = false
                    viewModel.generate()
                } label: {
                    Text("Generate")
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
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: message.contains("limit") || message.contains("budget") || message.contains("Upgrade") ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                            .foregroundStyle(message.contains("limit") || message.contains("budget") || message.contains("Upgrade") ? .orange : .red)
                            .font(.system(size: 16))
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundStyle(DS.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(message.contains("Upgrade") ? Color.orange.opacity(0.08) : Color.red.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(message.contains("Upgrade") ? Color.orange.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 0.5)
                            )
                    )

                    if message.contains("Upgrade") || message.contains("limit") || message.contains("budget") || message.contains("plan") {
                        Button {
                            appEnvironment.selectedTab = .subscriptions
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 14))
                                Text("Upgrade Plan")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
                        }
                    }

                    Button {
                        viewModel.reset()
                    } label: {
                        Text(message.contains("Upgrade") ? "Maybe Later" : "Try Again")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                }
            }
        }
    }

    // MARK: - Result

    private var resultSection: some View {
        Group {
            if case .completed(let url) = viewModel.state {
                GenerationResultCard(resultUrl: url, prompt: viewModel.prompt)
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        Group {
            if !viewModel.history.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent")
                        .font(DS.Typography.subtitle)
                        .foregroundStyle(DS.Colors.textPrimary)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                    ], spacing: 10) {
                        ForEach(viewModel.history.filter { $0.genType == .image && $0.statusValue == .completed }) { gen in
                            if let url = gen.resultUrl, let imageUrl = URL(string: url) {
                                AsyncImage(url: imageUrl) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(1, contentMode: .fill)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    case .failure:
                                        placeholderThumbnail
                                    default:
                                        SkeletonBlock(height: 160, width: nil, cornerRadius: 12)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(DS.Colors.fieldBackground)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(DS.Colors.textSecondary)
            }
    }

    // MARK: - Chip Button

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
