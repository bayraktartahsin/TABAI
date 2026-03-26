import Foundation

enum TABAIError: Error, LocalizedError {
    case offline
    case timeout
    case unauthenticated
    case invalidResponse
    case serverError(String)
    /// 429 rate limit — code from backend (e.g. "CHAT_DAILY_CATEGORY_LIMIT", "CHAT_CATEGORY_LOCKED")
    case rateLimited(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .offline: return "You appear to be offline."
        case .timeout: return "The request timed out."
        case .unauthenticated: return "Please sign in again."
        case .invalidResponse: return "Something went wrong. Please try again."
        case .serverError(let message): return message
        case .rateLimited(_, let message): return message
        }
    }

    var isRateLimited: Bool {
        if case .rateLimited = self { return true }
        return false
    }

    var rateLimitCode: String? {
        if case .rateLimited(let code, _) = self { return code }
        return nil
    }
}
