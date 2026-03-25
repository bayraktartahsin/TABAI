import Foundation

enum TABAIError: Error {
    case offline
    case timeout
    case unauthenticated
    case invalidResponse
}
