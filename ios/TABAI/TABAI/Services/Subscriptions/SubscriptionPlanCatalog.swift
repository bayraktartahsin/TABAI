import Foundation

enum BillingCycle: String, CaseIterable, Hashable {
    case monthly
    case yearly

    var title: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
}

struct SubscriptionPlan: Identifiable, Hashable {
    var id: String { "\(planTier.rawValue)-\(billingCycle.rawValue)" }
    let planTier: PlanTier
    let billingCycle: BillingCycle
    let productId: String
    let title: String
    let subtitle: String
}

enum SubscriptionPlanCatalog {
    static let orderedTiers: [PlanTier] = [.starter, .pro, .power]

    static var plans: [SubscriptionPlan] {
        var value: [SubscriptionPlan] = []

        for tier in orderedTiers {
            if let productId = AppConfig.iosSubscriptionProductMap[tier], productId.isEmpty == false {
                value.append(
                    SubscriptionPlan(
                        planTier: tier,
                        billingCycle: .monthly,
                        productId: productId,
                        title: displayName(for: tier),
                        subtitle: description(for: tier)
                    )
                )
            }

            if let yearlyProductId = AppConfig.iosSubscriptionYearlyProductMap[tier], yearlyProductId.isEmpty == false {
                value.append(
                    SubscriptionPlan(
                        planTier: tier,
                        billingCycle: .yearly,
                        productId: yearlyProductId,
                        title: displayName(for: tier),
                        subtitle: description(for: tier)
                    )
                )
            }
        }

        return value
    }

    static func plan(for productId: String) -> SubscriptionPlan? {
        plans.first(where: { $0.productId == productId })
    }

    static var backendPlanMappingGuide: [String: String] {
        var map: [String: String] = [:]
        for plan in plans {
            map["apple:\(plan.productId)"] = plan.planTier.rawValue
        }
        return map
    }

    static func displayName(for tier: PlanTier) -> String {
        switch tier {
        case .free: return "Free"
        case .starter: return "Starter"
        case .pro: return "Pro"
        case .power: return "Power"
        }
    }

    static func description(for tier: PlanTier) -> String {
        switch tier {
        case .free: return "Everyday answers with essential speed"
        case .starter: return "Faster daily chat, drafting, and reliable workflow speed"
        case .pro: return "Deeper reasoning, stronger quality, and heavier productivity work"
        case .power: return "Maximum depth, top-tier model quality, and highest throughput"
        }
    }
}
