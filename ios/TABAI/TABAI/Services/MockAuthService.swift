import Foundation

struct MockAuthService: AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> String {
        try await Task.sleep(nanoseconds: 600_000_000)
        return "demo-token-\(UUID().uuidString)"
    }

    func validateToken(_ token: String) async -> Bool {
        try? await Task.sleep(nanoseconds: 150_000_000)
        return token.hasPrefix("demo-token-")
    }

    func signOut(token: String) async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}
