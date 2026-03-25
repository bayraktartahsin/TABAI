import SwiftUI

/// Claude-style real-time usage display with progress bars and countdown
struct UsageView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @State private var snapshot: UsageSnapshot?
    @State private var isLoading = true
    @State private var error: String?
    @State private var refreshTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if isLoading && snapshot == nil {
                    loadingState
                } else if let snapshot {
                    usageCards(snapshot)
                } else if let error {
                    errorState(error)
                }
            }
            .padding(.horizontal, DS.Layout.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .taiFullscreen { GradientBackground() }
        .navigationTitle(L("Usage"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchUsage()
        }
        .refreshable {
            await fetchUsage()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L("Usage"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                if let snapshot {
                    Text(SubscriptionPlanCatalog.displayName(for: PlanTier(rawValue: snapshot.planTier) ?? .free))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DS.Colors.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            if let snapshot, let countdown = snapshot.resetCountdown {
                Text("Resets in \(countdown)")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func usageCards(_ s: UsageSnapshot) -> some View {
        // Show "Unlimited" for free tier
        if s.tokenLimit < 0 {
            HStack(spacing: 12) {
                Image(systemName: "infinity")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(DS.Colors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Unlimited Usage"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text(L("Free tier has no usage limits"))
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(cardBorder, lineWidth: 0.5)
            )
        } else {
            // 24-hour daily
            UsageProgressCard(
                title: L("Daily Tokens"),
                used: s.tokensUsed,
                limit: s.tokenLimit,
                progress: s.tokenProgress,
                icon: "text.word.spacing",
                formatValue: formatTokens,
                resetLabel: s.resetCountdown
            )

            // 4-week rolling
            if let weeklyUsed = s.weeklyTokensUsed, let weeklyLimit = s.weeklyTokenLimit, weeklyLimit > 0 {
                UsageProgressCard(
                    title: L("4-Week Rolling"),
                    used: weeklyUsed,
                    limit: weeklyLimit,
                    progress: s.weeklyTokenProgress,
                    icon: "calendar",
                    formatValue: formatTokens,
                    resetLabel: s.weeklyResetCountdown
                )
            }
        }

        // Request count
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(L("Requests today"))
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textSecondary)
                Text("\(s.requestCount)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(cardBorder, lineWidth: 0.5)
        )

        // Upgrade prompt
        if s.tokenProgress > 0.8 || s.costProgress > 0.8 {
            upgradePrompt
        }
    }

    private var upgradePrompt: some View {
        Button {
            Haptics.impact(.light)
            appEnvironment.selectedTab = .subscriptions
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Approaching limit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text("Upgrade for higher limits and premium models")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
            }
            .padding(14)
            .background(Color.yellow.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.yellow.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            SkeletonBlock(height: 100, width: nil)
            SkeletonBlock(height: 100, width: nil)
            SkeletonBlock(height: 60, width: nil)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(DS.Colors.textSecondary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await fetchUsage() }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(DS.Colors.accent)
        }
        .padding(.top, 40)
    }

    private func fetchUsage() async {
        isLoading = true
        error = nil
        do {
            let client = appEnvironment.tabaiClient
            let url = client.baseURL.appendingPathComponent("api/usage")
            let result: UsageSnapshot = try await client.requestJSON(method: "GET", url: url)
            snapshot = result
        } catch {
            self.error = "Could not load usage data. Pull to retry."
        }
        isLoading = false
    }

    private func formatTokens(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var cardBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor.white
        })
    }

    private var cardBorder: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.06)
        })
    }
}

// MARK: - Usage Progress Card

private struct UsageProgressCard: View {
    let title: String
    let used: Int
    let limit: Int
    let progress: Double
    let icon: String
    let formatValue: (Int) -> String
    var resetLabel: String? = nil

    private var progressColor: Color {
        if progress > 0.8 { return .red }
        if progress > 0.5 { return .yellow }
        return DS.Colors.accent
    }

    private var remaining: Int {
        max(0, limit - used)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)

                Spacer()

                Text("\(formatValue(used)) / \(formatValue(limit))")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            // Progress bar
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(progressTrackColor)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(progressColor)
                        .frame(width: max(0, proxy.size.width * progress), height: 8)
                        .animation(.easeOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(formatValue(remaining)) remaining")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textSecondary)

                Spacer()

                if let resetLabel {
                    Text("resets in \(resetLabel)")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                }

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(progressColor)
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(cardBorder, lineWidth: 0.5)
        )
    }

    private var cardBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor.white
        })
    }

    private var cardBorder: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.06)
        })
    }

    private var progressTrackColor: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.06)
                : UIColor.black.withAlphaComponent(0.06)
        })
    }
}
