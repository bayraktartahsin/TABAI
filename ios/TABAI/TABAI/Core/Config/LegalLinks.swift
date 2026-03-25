import Foundation

enum LegalLinkKey: String, CaseIterable {
    case privacy
    case terms
    case acceptableUse
    case subscription
    case support

    var title: String {
        switch self {
        case .privacy:
            return "Privacy"
        case .terms:
            return "Terms"
        case .acceptableUse:
            return "Acceptable Use"
        case .subscription:
            return "Subscription"
        case .support:
            return "Support"
        }
    }
}

enum LegalLinks {
    static let privacy = URL(string: "https://ai.gravitilabs.com/tabai/privacy")!
    static let terms = URL(string: "https://ai.gravitilabs.com/tabai/terms")!
    static let acceptableUse = URL(string: "https://ai.gravitilabs.com/tabai/acceptable-use")!
    static let subscription = URL(string: "https://ai.gravitilabs.com/tabai/subscription")!
    static let support = URL(string: "https://ai.gravitilabs.com/tabai/support")!

    static func url(for key: LegalLinkKey) -> URL {
        switch key {
        case .privacy:
            return privacy
        case .terms:
            return terms
        case .acceptableUse:
            return acceptableUse
        case .subscription:
            return subscription
        case .support:
            return support
        }
    }
}
