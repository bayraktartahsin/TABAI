import SwiftUI

// MARK: - Limit Type

enum LimitReachedType {
    case chatDailyCategory(modelName: String, used: Int, limit: Int)
    case chatModelLocked(modelName: String, requiredTier: String)
    case generationDailyImage(used: Int, limit: Int)
    case generationMonthlyImage(used: Int, limit: Int)
    case generationDailyVideo(used: Int, limit: Int)
    case generationMonthlyVideo(used: Int, limit: Int)
    case generationBudget
    case generationTierLocked(feature: String)

    var icon: String {
        switch self {
        case .chatDailyCategory: return "bubble.left.and.text.bubble.right"
        case .chatModelLocked: return "lock.shield"
        case .generationDailyImage, .generationMonthlyImage: return "photo.stack"
        case .generationDailyVideo, .generationMonthlyVideo: return "film.stack"
        case .generationBudget: return "gauge.with.needle"
        case .generationTierLocked: return "crown"
        }
    }

    var iconColor: Color {
        switch self {
        case .chatDailyCategory, .generationDailyImage, .generationDailyVideo: return .orange
        case .chatModelLocked, .generationTierLocked: return .purple
        case .generationMonthlyImage, .generationMonthlyVideo: return .pink
        case .generationBudget: return .red
        }
    }

    var title: String {
        switch self {
        case .chatDailyCategory: return "Daily limit reached"
        case .chatModelLocked: return "Model locked"
        case .generationDailyImage: return "Daily image limit"
        case .generationMonthlyImage: return "Monthly image limit"
        case .generationDailyVideo: return "Daily video limit"
        case .generationMonthlyVideo: return "Monthly video limit"
        case .generationBudget: return "Budget exhausted"
        case .generationTierLocked: return "Upgrade required"
        }
    }

    var subtitle: String {
        switch self {
        case .chatDailyCategory(let model, let used, let limit):
            return "You've sent \(used) of \(limit) messages today with \(model). Your quota resets at midnight UTC."
        case .chatModelLocked(let model, let tier):
            return "\(model) requires a \(tier) plan. Upgrade to unlock this model and many more."
        case .generationDailyImage(let used, let limit):
            return "You've created \(used) of \(limit) images today. Come back tomorrow or upgrade for more."
        case .generationMonthlyImage(let used, let limit):
            return "You've created \(used) of \(limit) images this month. Upgrade your plan for a higher monthly allowance."
        case .generationDailyVideo(let used, let limit):
            return "You've created \(used) of \(limit) videos today. Come back tomorrow or upgrade for more."
        case .generationMonthlyVideo(let used, let limit):
            return "You've created \(used) of \(limit) videos this month. Upgrade for more monthly videos."
        case .generationBudget:
            return "You've used your entire monthly generation budget. Upgrade for a bigger budget."
        case .generationTierLocked(let feature):
            return "\(feature) requires a higher plan. Upgrade to unlock this feature."
        }
    }

    var showTimer: Bool {
        switch self {
        case .chatDailyCategory, .generationDailyImage, .generationDailyVideo: return true
        default: return false
        }
    }
}

// MARK: - Limit Reached Sheet

struct LimitReachedSheet: View {
    let type: LimitReachedType
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    @State private var animateIcon = false
    @State private var timeUntilReset: String = ""
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            VStack(spacing: 20) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(type.iconColor.opacity(0.12))
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(type.iconColor.opacity(0.06))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIcon ? 1.15 : 1.0)

                    Image(systemName: type.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(type.iconColor)
                        .symbolEffect(.pulse, options: .repeating, value: animateIcon)
                }
                .padding(.top, 24)

                // Title + subtitle
                VStack(spacing: 8) {
                    Text(type.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(DS.Colors.textPrimary)

                    Text(type.subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }

                // Timer countdown for daily limits
                if type.showTimer {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Colors.textSecondary)
                        Text("Resets in \(timeUntilReset)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(Capsule())
                }

                // Progress bar for counted limits
                if case .chatDailyCategory(_, let used, let limit) = type, limit > 0 {
                    usageBar(used: used, limit: limit, label: "messages used today")
                } else if case .generationMonthlyImage(let used, let limit) = type, limit > 0 {
                    usageBar(used: used, limit: limit, label: "images this month")
                } else if case .generationMonthlyVideo(let used, let limit) = type, limit > 0 {
                    usageBar(used: used, limit: limit, label: "videos this month")
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        Haptics.impact(.medium)
                        onUpgrade()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16))
                            Text("Upgrade Plan")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [type.iconColor, type.iconColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onDismiss()
                    } label: {
                        Text(type.showTimer ? "I'll wait" : "Maybe later")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DS.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.12, blue: 0.16),
                            Color(red: 0.06, green: 0.08, blue: 0.12),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
            updateTimer()
            if type.showTimer {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    updateTimer()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Usage Bar

    private func usageBar(used: Int, limit: Int, label: String) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [type.iconColor.opacity(0.8), type.iconColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(1.0, CGFloat(used) / max(1, CGFloat(limit))), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(used)/\(limit) \(label)")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textSecondary)
                Spacer()
                Text("100%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(type.iconColor)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Timer

    private func updateTimer() {
        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        guard let midnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) else {
            timeUntilReset = "--:--:--"
            return
        }
        let diff = calendar.dateComponents([.hour, .minute, .second], from: now, to: midnight)
        let h = diff.hour ?? 0
        let m = diff.minute ?? 0
        let s = diff.second ?? 0
        timeUntilReset = String(format: "%02d:%02d:%02d", h, m, s)
    }
}
