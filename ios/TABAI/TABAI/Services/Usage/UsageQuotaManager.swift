import Foundation
import Combine

@MainActor
final class UsageQuotaManager: ObservableObject {
    enum PremiumModelAccess: String {
        case none
        case partial
        case full
    }

    struct QuotaSnapshot {
        let planTier: PlanTier
        let planName: String
        let dailyQuotaRemaining: Int?
        let weeklyQuotaRemaining: Int?
        let dailyResetCountdown: String?
        let weeklyResetCountdown: String?
        let premiumModelAccess: PremiumModelAccess
    }

    static let shared = UsageQuotaManager()

    @Published private(set) var now: Date = Date()

    private let calendar = Calendar(identifier: .gregorian)
    private let defaults = UserDefaults.standard
    private var timer: Timer?

    private init() {
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    func canSendRequest(planTier: PlanTier) -> Bool {
        resetIfNeeded(planTier: planTier)
        let policy = policy(for: planTier)

        if let dailyLimit = policy.dailyCredits {
            let used = defaults.integer(forKey: usageKey(planTier: planTier, period: .daily))
            if used >= dailyLimit { return false }
        }

        if let weeklyLimit = policy.weeklyCredits {
            let used = defaults.integer(forKey: usageKey(planTier: planTier, period: .weekly))
            if used >= weeklyLimit { return false }
        }

        return true
    }

    func consumeRequest(planTier: PlanTier) {
        resetIfNeeded(planTier: planTier)
        let policy = policy(for: planTier)

        if policy.dailyCredits != nil {
            let key = usageKey(planTier: planTier, period: .daily)
            defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
        }

        if policy.weeklyCredits != nil {
            let key = usageKey(planTier: planTier, period: .weekly)
            defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
        }
    }

    func snapshot(for planTier: PlanTier) -> QuotaSnapshot {
        resetIfNeeded(planTier: planTier)
        let policy = policy(for: planTier)

        let dailyRemaining: Int?
        if let daily = policy.dailyCredits {
            let used = defaults.integer(forKey: usageKey(planTier: planTier, period: .daily))
            dailyRemaining = max(0, daily - used)
        } else {
            dailyRemaining = nil
        }

        let weeklyRemaining: Int?
        if let weekly = policy.weeklyCredits {
            let used = defaults.integer(forKey: usageKey(planTier: planTier, period: .weekly))
            weeklyRemaining = max(0, weekly - used)
        } else {
            weeklyRemaining = nil
        }

        return QuotaSnapshot(
            planTier: planTier,
            planName: SubscriptionPlanCatalog.displayName(for: planTier),
            dailyQuotaRemaining: dailyRemaining,
            weeklyQuotaRemaining: weeklyRemaining,
            dailyResetCountdown: dailyRemaining != nil ? countdown(until: nextDailyResetDate()) : nil,
            weeklyResetCountdown: weeklyRemaining != nil ? countdown(until: nextWeeklyResetDate()) : nil,
            premiumModelAccess: policy.premiumModelAccess
        )
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
            }
        }
        timer?.tolerance = 0.2
    }

    private enum Period {
        case daily
        case weekly
    }

    private struct Policy {
        let dailyCredits: Int?
        let weeklyCredits: Int?
        let premiumModelAccess: PremiumModelAccess
    }

    private func policy(for tier: PlanTier) -> Policy {
        switch tier {
        case .free:
            return Policy(dailyCredits: nil, weeklyCredits: nil, premiumModelAccess: .none)
        case .starter:
            return Policy(dailyCredits: nil, weeklyCredits: nil, premiumModelAccess: .none)
        case .pro:
            return Policy(dailyCredits: nil, weeklyCredits: nil, premiumModelAccess: .partial)
        case .power:
            return Policy(dailyCredits: nil, weeklyCredits: nil, premiumModelAccess: .full)
        }
    }

    private func usageKey(planTier: PlanTier, period: Period) -> String {
        "tai.usage.\(period == .daily ? "daily" : "weekly").\(planTier.rawValue).used"
    }

    private func markerKey(planTier: PlanTier, period: Period) -> String {
        "tai.usage.\(period == .daily ? "daily" : "weekly").\(planTier.rawValue).marker"
    }

    private func resetIfNeeded(planTier: PlanTier) {
        let dailyMarker = currentDayMarker()
        let savedDailyMarker = defaults.string(forKey: markerKey(planTier: planTier, period: .daily))
        if savedDailyMarker != dailyMarker {
            defaults.set(0, forKey: usageKey(planTier: planTier, period: .daily))
            defaults.set(dailyMarker, forKey: markerKey(planTier: planTier, period: .daily))
        }

        let weeklyMarker = currentWeekMarker()
        let savedWeeklyMarker = defaults.string(forKey: markerKey(planTier: planTier, period: .weekly))
        if savedWeeklyMarker != weeklyMarker {
            defaults.set(0, forKey: usageKey(planTier: planTier, period: .weekly))
            defaults.set(weeklyMarker, forKey: markerKey(planTier: planTier, period: .weekly))
        }
    }

    private func currentDayMarker() -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private func currentWeekMarker() -> String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        return "\(components.yearForWeekOfYear ?? 0)-w\(components.weekOfYear ?? 0)"
    }

    private func nextDailyResetDate() -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
    }

    private func nextWeeklyResetDate() -> Date {
        let week = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let weekStart = calendar.date(from: week) ?? now
        return calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
    }

    private func countdown(until date: Date) -> String {
        let delta = max(0, Int(date.timeIntervalSince(now)))
        let hours = delta / 3600
        let minutes = (delta % 3600) / 60
        let seconds = delta % 60
        return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
    }
}
