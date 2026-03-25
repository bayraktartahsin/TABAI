import SwiftUI

struct MessageActionMenu: View {
    let isUser: Bool
    let isStreaming: Bool
    let isFailed: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onRegenerate: () -> Void
    let onStop: () -> Void
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ActionChip(title: t("chat.copy", fallback: "Copy"), icon: "doc.on.doc", prominence: .primary, action: onCopy)

            if isUser {
                ActionChip(title: t("chat.edit", fallback: "Edit"), icon: "pencil", prominence: .secondary, action: onEdit)
            } else {
                if isStreaming {
                    ActionChip(title: t("chat.stop", fallback: "Stop"), icon: "stop.fill", prominence: .danger, action: onStop)
                } else {
                    if isFailed {
                        ActionChip(title: t("chat.retry", fallback: "Retry"), icon: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90", prominence: .danger, action: onRetry)
                    } else {
                        ActionChip(title: t("chat.regenerate", fallback: "Regenerate"), icon: "arrow.clockwise", prominence: .secondary, action: onRegenerate)
                        ActionChip(title: t("chat.retry", fallback: "Retry"), icon: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90", prominence: .secondary, action: onRetry)
                    }
                }
            }
        }
        .foregroundStyle(DS.Colors.textSecondary)
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, 3)
        .padding(.top, 1)
    }
}

private struct ActionChip: View {
    enum Prominence {
        case primary
        case secondary
        case danger
    }

    let title: String
    let icon: String
    let prominence: Prominence
    let action: () -> Void

    private var foreground: Color {
        switch prominence {
        case .danger:
            return .orange
        case .primary:
            return DS.Colors.textPrimary
        case .secondary:
            return DS.Colors.textSecondary
        }
    }

    private var background: Color {
        switch prominence {
        case .danger:
            return Color.orange.opacity(0.13)
        case .primary:
            return DS.Colors.fieldBackground.opacity(0.95)
        case .secondary:
            return DS.Colors.fieldBackground.opacity(0.75)
        }
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
                .contentShape(Capsule())
                .background(background)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(DS.Colors.glassStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}
