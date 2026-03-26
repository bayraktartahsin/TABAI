import Foundation
import StoreKit

struct StoreSyncResult {
    let accepted: Bool
    let provider: String
    let verificationState: String
    let code: String
    let message: String
    let entitlement: EntitlementInfo?
    let latestEntitlement: EntitlementInfo?
    let debugSummary: String?

    var isEntitlementActive: Bool {
        guard let entitlement else { return false }
        return entitlement.status == .active || entitlement.status == .grace
    }
}

struct StoreEntitlementSyncService {
    enum Error: Swift.Error {
        case invalidResponse(statusCode: Int?, bodySnippet: String?)
        case backendRejected(statusCode: Int, code: String?, message: String, debugSummary: String?, bodySnippet: String?)
    }

    private let client: TABAIClient

    init(client: TABAIClient) {
        self.client = client
    }

    func syncApple(transaction: Transaction, rawPayload: [String: Any]? = nil) async throws -> StoreSyncResult {
        var payload: [String: Any] = [
            "provider": "apple",
            "transactionId": String(transaction.id),
            "productId": transaction.productID,
            "originalTransactionId": String(transaction.originalID)
        ]

        if #available(iOS 16.0, *) {
            payload["environment"] = transaction.environment == .sandbox ? "sandbox" : "production"
        }

        if let rawPayload {
            payload["rawPayload"] = rawPayload
        }

        if AppConfig.enableStoreKitDebugLogs {
            TABLogger.debug("TAI entitlement sync request: provider=apple productId=\(transaction.productID) tx=\(transaction.id)")
        }

        let body = try JSONSerialization.data(withJSONObject: payload)
        let endpoint = client.baseURL.appendingPathComponent("api/entitlements/store/sync")
        let (data, response) = try await client.requestRaw(method: "POST", url: endpoint, body: body)
        let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let responseCode = responseJSON?["code"] as? String
        let responseMessage = (responseJSON?["message"] as? String)
            ?? (responseJSON?["error"] as? String)
            ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
        let debugSummary = responseJSON?["debugSummary"] as? String
        let bodySnippet = responseBodySnippet(data)

        guard response.statusCode == 202 else {
            if AppConfig.enableStoreKitDebugLogs {
                TABLogger.debug("TAI entitlement sync failed status: \(response.statusCode) code=\(responseCode ?? "<none>") message=\(responseMessage)")
            }
            throw Error.backendRejected(
                statusCode: response.statusCode,
                code: responseCode,
                message: responseMessage,
                debugSummary: debugSummary,
                bodySnippet: bodySnippet
            )
        }
        guard
            let json = responseJSON,
            let accepted = json["accepted"] as? Bool,
            let provider = json["provider"] as? String,
            let verificationState = json["verificationState"] as? String,
            let code = json["code"] as? String,
            let message = json["message"] as? String
        else {
            throw Error.invalidResponse(statusCode: response.statusCode, bodySnippet: bodySnippet)
        }
        if AppConfig.enableStoreKitDebugLogs {
            TABLogger.debug("TAI entitlement sync response: state=\(verificationState) code=\(code)")
            if let debugSummary, debugSummary.isEmpty == false {
                TABLogger.debug("TAI entitlement sync debug: \(debugSummary)")
            }
        }
        return StoreSyncResult(
            accepted: accepted,
            provider: provider,
            verificationState: verificationState,
            code: code,
            message: message,
            entitlement: parseEntitlement(json["entitlement"]),
            latestEntitlement: parseEntitlement(json["latestEntitlement"]),
            debugSummary: debugSummary
        )
    }

    static func userFacingMessage(for error: Swift.Error) -> String {
        switch error {
        case Error.backendRejected(let statusCode, let code, let message, _, _):
            if let code, code.isEmpty == false {
                return "Backend sync failed (HTTP \(statusCode), \(code)): \(message)"
            }
            return "Backend sync failed (HTTP \(statusCode)): \(message)"
        case Error.invalidResponse(let statusCode, _):
            if let statusCode {
                return "Backend sync returned an invalid response (HTTP \(statusCode))."
            }
            return "Backend sync returned an invalid response."
        case TABAIError.unauthenticated:
            return "No valid backend session. Sign in again, then retry restore."
        case TABAIError.offline:
            return "Network connection is offline."
        case TABAIError.timeout:
            return "Backend sync timed out."
        default:
            return "Backend sync failed: \(error.localizedDescription)"
        }
    }

    static func debugSummary(for error: Swift.Error) -> String? {
        switch error {
        case Error.backendRejected(let statusCode, let code, let message, let debugSummary, let bodySnippet):
            return [
                "http=\(statusCode)",
                code.flatMap { $0.isEmpty ? nil : "code=\($0)" },
                message.isEmpty ? nil : "message=\(message)",
                debugSummary.flatMap { $0.isEmpty ? nil : $0 },
                bodySnippet.flatMap { $0.isEmpty ? nil : "body=\($0)" }
            ]
            .compactMap { $0 }
            .joined(separator: " | ")
        case Error.invalidResponse(let statusCode, let bodySnippet):
            return [
                statusCode.map { "http=\($0)" },
                bodySnippet.flatMap { $0.isEmpty ? nil : "body=\($0)" }
            ]
            .compactMap { $0 }
            .joined(separator: " | ")
        case TABAIError.unauthenticated:
            return "client=no_session_cookie"
        case TABAIError.offline:
            return "client=offline"
        case TABAIError.timeout:
            return "client=timeout"
        default:
            return nil
        }
    }

    private func responseBodySnippet(_ data: Data) -> String? {
        guard data.isEmpty == false else { return nil }
        let snippet = String(data: data.prefix(400), encoding: .utf8) ?? "<binary>"
        return snippet.replacingOccurrences(of: "\n", with: " ")
    }

    private func parseEntitlement(_ value: Any?) -> EntitlementInfo? {
        guard
            let dict = value as? [String: Any],
            let id = dict["id"] as? String,
            let userId = dict["userId"] as? String,
            let planTierRaw = dict["planTier"] as? String,
            let sourceRaw = dict["source"] as? String,
            let statusRaw = dict["status"] as? String,
            let planTier = PlanTier(rawValue: planTierRaw.lowercased()),
            let source = EntitlementSource(rawValue: sourceRaw.lowercased()),
            let status = EntitlementStatus(rawValue: statusRaw.lowercased()),
            let startAtRaw = dict["startAt"] as? String,
            let updatedAtRaw = dict["updatedAt"] as? String,
            let startAt = parseDate(startAtRaw),
            let updatedAt = parseDate(updatedAtRaw)
        else {
            return nil
        }

        return EntitlementInfo(
            id: id,
            userId: userId,
            planTier: planTier,
            source: source,
            status: status,
            startAt: startAt,
            expiresAt: parseDate(dict["expiresAt"] as? String),
            autoRenew: (dict["autoRenew"] as? Bool) ?? false,
            externalProductId: dict["externalProductId"] as? String,
            externalOriginalTransactionId: dict["externalOriginalTransactionId"] as? String,
            lastValidatedAt: parseDate(dict["lastValidatedAt"] as? String),
            updatedAt: updatedAt
        )
    }

    private func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) {
            return date
        }
        return ISO8601DateFormatter().date(from: raw)
    }
}
