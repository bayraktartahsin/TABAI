import Foundation

struct TABAIConfiguration {
    let baseURL: URL
    let apiKey: String?
    let cookieAuthEnabled: Bool
}

let taiCookieSessionSentinel = "__tai_cookie_session__"

final class TABAIClient {
    let baseURL: URL
    private let configuration: TABAIConfiguration
    private let session: URLSession
    private let tokenProvider: () -> String?

    init(configuration: TABAIConfiguration, session: URLSession? = nil, tokenProvider: @escaping () -> String?) {
        self.configuration = configuration
        self.baseURL = configuration.baseURL
        self.tokenProvider = tokenProvider
        if let session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.timeoutIntervalForRequest = AppConfig.requestTimeoutSeconds
            sessionConfiguration.timeoutIntervalForResource = AppConfig.streamTimeoutSeconds
            sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
            sessionConfiguration.httpShouldSetCookies = configuration.cookieAuthEnabled
            sessionConfiguration.httpCookieAcceptPolicy = .always
            sessionConfiguration.httpCookieStorage = .shared
            self.session = URLSession(configuration: sessionConfiguration)
        }
    }

    func requestJSON<T: Decodable>(method: String, url: URL, body: Data? = nil) async throws -> T {
        let (data, _) = try await requestRaw(method: method, url: url, body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func requestRaw(method: String, url: URL, body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        if requiresAuthenticatedSession(url: url) && hasSessionCredential() == false {
            if AppConfig.enableNetworkDebugLogs {
                print("TAI blocked unauthenticated request: \(method) \(url.absoluteString)")
            }
            throw TABAIError.unauthenticated
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let authorization = authorizationHeaderValue() {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }

        if AppConfig.enableNetworkDebugLogs {
            print("TAI request: \(method) \(url.absoluteString)")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TABAIError.invalidResponse
            }
            if AppConfig.enableNetworkDebugLogs {
                let snippet = String(data: data.prefix(300), encoding: .utf8) ?? "<binary>"
                print("TAI response: \(httpResponse.statusCode) \(snippet)")
            }
            return (data, httpResponse)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw TABAIError.offline
            case .timedOut:
                throw TABAIError.timeout
            default:
                throw error
            }
        }
    }

    func streamSSE(url: URL, body: Data?, onEvent: @escaping (String, Data) -> Void) async throws {
        if requiresAuthenticatedSession(url: url) && hasSessionCredential() == false {
            if AppConfig.enableNetworkDebugLogs {
                print("TAI blocked unauthenticated stream: \(url.absoluteString)")
            }
            throw TABAIError.unauthenticated
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = AppConfig.streamTimeoutSeconds
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        if let authorization = authorizationHeaderValue() {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }

        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TABAIError.invalidResponse
            }

            var eventName: String?
            var dataBuffer = ""
            for try await line in bytes.lines {
                if Task.isCancelled { break }
                if line.hasPrefix("event:") {
                    if let eventName, let data = dataBuffer.data(using: .utf8), dataBuffer.isEmpty == false {
                        onEvent(eventName, data)
                        dataBuffer = ""
                    }
                    eventName = line.replacingOccurrences(of: "event:", with: "").trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("data:") {
                    let dataLine = line.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
                    if dataBuffer.isEmpty {
                        dataBuffer = dataLine
                    } else {
                        dataBuffer += "\n\(dataLine)"
                    }
                } else if line.isEmpty {
                    if let eventName, let data = dataBuffer.data(using: .utf8) {
                        onEvent(eventName, data)
                    }
                    eventName = nil
                    dataBuffer = ""
                }
            }
            if let eventName, let data = dataBuffer.data(using: .utf8), dataBuffer.isEmpty == false {
                onEvent(eventName, data)
            }
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw TABAIError.offline
            case .timedOut:
                throw TABAIError.timeout
            default:
                throw error
            }
        }
    }

    private func authorizationHeaderValue() -> String? {
        if AppConfig.authMode == .apiKey, let apiKey = configuration.apiKey, apiKey.isEmpty == false {
            return "Bearer \(apiKey)"
        }
        if let token = tokenProvider(), token.isEmpty == false, token != taiCookieSessionSentinel {
            return "Bearer \(token)"
        }
        return nil
    }

    private func requiresAuthenticatedSession(url: URL) -> Bool {
        let path = url.path
        if path.hasPrefix("/api/") == false {
            return false
        }
        let publicPaths = Set([
            "/api/health",
            "/api/auth/signin",
            "/api/auth/signout",
        ])
        return publicPaths.contains(path) == false
    }

    private func hasSessionCredential() -> Bool {
        if authorizationHeaderValue() != nil {
            return true
        }
        let cookies = HTTPCookieStorage.shared.cookies(for: baseURL) ?? []
        return cookies.contains(where: { $0.name == "tai_session" && $0.value.isEmpty == false })
    }
}
