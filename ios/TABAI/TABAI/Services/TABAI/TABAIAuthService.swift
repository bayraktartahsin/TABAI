import Foundation

struct TABAIAuthService: AuthServiceProtocol {
    enum Error: Swift.Error {
        case notImplemented
        case invalidResponse
        case emailNotVerified
        case invalidCredentials
    }

    let client: TABAIClient

    func signIn(email: String, password: String) async throws -> String {
        if let apiKey = AppConfig.tabaiAPIKey, apiKey.isEmpty == false, AppConfig.authMode == .apiKey {
            return "api-key"
        }

        let url = client.baseURL.appendingPathComponent("api/auth/signin")
        let body = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        let (data, response) = try await client.requestRaw(method: "POST", url: url, body: body)
        guard response.statusCode == 200 else {
            // Parse error code from response body
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let code = json["code"] as? String {
                switch code {
                case "EMAIL_NOT_VERIFIED":
                    throw Error.emailNotVerified
                case "INVALID_CREDENTIALS":
                    throw Error.invalidCredentials
                default:
                    break
                }
            }
            throw Error.invalidResponse
        }
        return taiCookieSessionSentinel
    }

    func validateToken(_ token: String) async -> Bool {
        if let apiKey = AppConfig.tabaiAPIKey, apiKey.isEmpty == false, AppConfig.authMode == .apiKey {
            return true
        }

        let url = client.baseURL.appendingPathComponent("api/auth/me")
        do {
            let (_, response) = try await client.requestRaw(method: "GET", url: url)
            return response.statusCode == 200
        } catch {
            return false
        }
    }

    func signOut(token: String) async {
        let url = client.baseURL.appendingPathComponent("api/auth/signout")
        _ = try? await client.requestRaw(method: "POST", url: url)
    }

    func requestVerification(email: String) async throws {
        let url = client.baseURL.appendingPathComponent("api/auth/verify/request")
        let body = try JSONSerialization.data(withJSONObject: ["email": email])
        let (_, response) = try await client.requestRaw(method: "POST", url: url, body: body)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }
    }

    func requestPasswordReset(email: String) async throws {
        let url = client.baseURL.appendingPathComponent("api/auth/password-reset/request")
        let body = try JSONSerialization.data(withJSONObject: ["email": email])
        let (_, response) = try await client.requestRaw(method: "POST", url: url, body: body)
        guard response.statusCode == 200 else {
            throw Error.invalidResponse
        }
    }
}
