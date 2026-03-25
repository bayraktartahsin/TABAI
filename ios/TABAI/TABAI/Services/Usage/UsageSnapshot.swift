import Foundation

/// Server-side usage snapshot from GET /api/usage with 3 time windows
struct UsageSnapshot: Codable {
    let planTier: String

    // 5-hour burst window
    let burstTokensUsed: Int?
    let burstTokenLimit: Int?
    let burstCostUsed: Int?
    let burstCostLimit: Int?
    let burstResetAt: String?

    // 24-hour daily window
    let tokensUsed: Int
    let tokenLimit: Int
    let costUnitsUsed: Int
    let costUnitLimit: Int
    let resetAt: String

    // 7-day weekly window
    let weeklyTokensUsed: Int?
    let weeklyTokenLimit: Int?
    let weeklyCostUsed: Int?
    let weeklyCostLimit: Int?
    let weeklyResetAt: String?

    // General
    let requestCount: Int
    let windowHours: Int

    // MARK: - Daily

    var tokenProgress: Double {
        guard tokenLimit > 0 else { return 0 }
        return min(1.0, Double(tokensUsed) / Double(tokenLimit))
    }

    var costProgress: Double {
        guard costUnitLimit > 0 else { return 0 }
        return min(1.0, Double(costUnitsUsed) / Double(costUnitLimit))
    }

    var tokensRemaining: Int { max(0, tokenLimit - tokensUsed) }
    var costUnitsRemaining: Int { max(0, costUnitLimit - costUnitsUsed) }

    // MARK: - Burst

    var burstTokenProgress: Double {
        guard let limit = burstTokenLimit, let used = burstTokensUsed, limit > 0 else { return 0 }
        return min(1.0, Double(used) / Double(limit))
    }

    // MARK: - Weekly

    var weeklyTokenProgress: Double {
        guard let limit = weeklyTokenLimit, let used = weeklyTokensUsed, limit > 0 else { return 0 }
        return min(1.0, Double(used) / Double(limit))
    }

    // MARK: - Countdowns

    var resetCountdown: String? { countdown(from: resetAt) }
    var burstResetCountdown: String? { burstResetAt.flatMap { countdown(from: $0) } }
    var weeklyResetCountdown: String? { weeklyResetAt.flatMap { countdown(from: $0) } }

    private func countdown(from isoString: String) -> String? {
        guard let date = ISO8601DateFormatter().date(from: isoString) else { return nil }
        let seconds = max(0, date.timeIntervalSinceNow)
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
