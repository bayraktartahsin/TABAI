import Foundation

protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> String
    func validateToken(_ token: String) async -> Bool
    func signOut(token: String) async
}
