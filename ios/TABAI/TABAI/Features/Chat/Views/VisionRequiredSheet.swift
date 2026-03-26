import SwiftUI

/// Premium sheet shown when a user tries to send image attachments with a non-vision model.
/// Offers quick-switch to vision models or removal of attachments.
struct VisionRequiredSheet: View {
    let currentModelName: String?
    let visionModels: [ModelCatalog.Model]
    let onSelectModel: (String) -> Void
    let onRemoveImages: () -> Void
    let onOpenPlans: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let topVisionModelIds: [String] = [
        "openai/gpt-4o",
        "anthropic/claude-sonnet-4",
        "anthropic/claude-3.5-sonnet",
        "google/gemini-2.0-flash-001",
        "google/gemini-pro-vision",
        "meta-llama/llama-3.2-11b-vision-instruct"
    ]

    private var suggestedModels: [ModelCatalog.Model] {
        // Show up to 4 vision models, prioritising well-known ones
        let preferred = topVisionModelIds.compactMap { id in
            visionModels.first(where: { $0.id == id || $0.providerModelId == id })
        }
        let remaining = visionModels.filter { model in
            !preferred.contains(where: { $0.id == model.id })
        }
        return Array((preferred + remaining).prefix(4))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.25))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.80, blue: 0.70).opacity(0.2),
                                Color(red: 0.35, green: 0.80, blue: 0.70).opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(DS.Colors.accent)
            }
            .padding(.bottom, 16)

            // Title
            Text("Vision Model Required")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Colors.textPrimary)
                .padding(.bottom, 6)

            // Subtitle
            Text(subtitleText)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

            // Suggested models
            if !suggestedModels.isEmpty {
                VStack(spacing: 0) {
                    Text("SWITCH TO A VISION MODEL")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
                        .tracking(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 10)

                    VStack(spacing: 8) {
                        ForEach(suggestedModels) { model in
                            modelRow(model)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }

            // Divider
            Rectangle()
                .fill(DS.Colors.glassStroke)
                .frame(height: 0.5)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            // Secondary actions
            VStack(spacing: 10) {
                Button {
                    dismiss()
                    onRemoveImages()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.minus")
                            .font(.system(size: 14))
                        Text("Remove images and send as text")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var subtitleText: String {
        if let name = currentModelName, !name.isEmpty {
            return "Your attached images require a model with vision capabilities. \(name) can\u{2019}t process images."
        }
        return "Your attached images require a model with vision capabilities. The current model can\u{2019}t process images."
    }

    @ViewBuilder
    private func modelRow(_ model: ModelCatalog.Model) -> some View {
        Button {
            dismiss()
            onSelectModel(model.id)
        } label: {
            HStack(spacing: 12) {
                // Model icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(DS.Colors.fieldBackground)
                        .frame(width: 40, height: 40)

                    if let logoURL = model.logoURL, let url = URL(string: logoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        } placeholder: {
                            Image(systemName: "eye")
                                .font(.system(size: 16))
                                .foregroundStyle(DS.Colors.accent)
                        }
                    } else {
                        Image(systemName: "eye")
                            .font(.system(size: 16))
                            .foregroundStyle(DS.Colors.accent)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName ?? model.id)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Label("Vision", systemImage: "eye.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DS.Colors.accent)

                        if let vendor = model.vendor {
                            Text(vendor)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                        }

                        tierBadge(model.requiredPlanTier)
                    }
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(DS.Colors.accent.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DS.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(DS.Colors.glassStroke, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tierBadge(_ tier: PlanTier) -> some View {
        let (label, color): (String, Color) = {
            switch tier {
            case .free: return ("Free", .green)
            case .starter: return ("Starter", DS.Colors.accent)
            case .pro: return ("Pro", .orange)
            case .power: return ("Power", .purple)
            }
        }()

        Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }
}
