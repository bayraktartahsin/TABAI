import Foundation

struct TABAIDiscoveryResult {
    let openAPIURL: URL
    let baseAPIURL: URL
    let detectedAuthSchemes: [String]
    let paths: [String: TABAIPathInfo]
}

struct TABAIPathInfo {
    let methods: [String]
    let tagsByMethod: [String: [String]]
}

enum TABAIDiscovery {
    static func discover(baseURL: URL, session: URLSession = .shared) async -> TABAIDiscoveryResult? {
        guard AppConfig.enableDiscovery else {
            if AppConfig.enableNetworkDebugLogs {
                TABLogger.debug("TABAI discovery disabled; using local configuration")
            }
            return nil
        }

        let candidates = [
            "openapi.json",
            "api/v1/openapi.json",
            "open-webui/openapi.json",
            "openwebui/openapi.json",
            "openwebui/api/v1/openapi.json",
            "open-webui/api/v1/openapi.json"
        ]

        let baseCandidates = buildBaseCandidates(from: baseURL, apiPrefix: AppConfig.tabaiAPIPrefix)
        var errors: [String] = []

        for base in baseCandidates {
            for path in candidates {
                guard let url = URL(string: path, relativeTo: base) else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.cachePolicy = .reloadIgnoringLocalCacheData

                do {
                    let (data, response) = try await session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        errors.append("\(url.absoluteString): no http response")
                        continue
                    }
                    guard httpResponse.statusCode == 200 else {
                        errors.append("\(url.absoluteString): status \(httpResponse.statusCode)")
                        continue
                    }
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        errors.append("\(url.absoluteString): invalid json")
                        continue
                    }
                    guard json["openapi"] != nil, json["paths"] != nil else {
                        errors.append("\(url.absoluteString): missing openapi/paths")
                        continue
                    }

                    let baseAPIURL = url.deletingLastPathComponent()
                    let paths = parsePaths(json["paths"])
                    let authSchemes = parseAuthSchemes(json["components"])

                    if AppConfig.enableNetworkDebugLogs {
                        TABLogger.debug("TABAI OpenAPI found at: \(url.absoluteString)")
                        TABLogger.debug("Base API URL: \(baseAPIURL.absoluteString)")
                        TABLogger.debug("Detected auth: \(authSchemes.joined(separator: ", "))")
                    }

                    AppConfig.discoveredOpenAPIURL = url.absoluteString
                    return TABAIDiscoveryResult(
                        openAPIURL: url,
                        baseAPIURL: baseAPIURL,
                        detectedAuthSchemes: authSchemes,
                        paths: paths
                    )
                } catch {
                    errors.append("\(url.absoluteString): \(error.localizedDescription)")
                    continue
                }
            }
        }

        if AppConfig.enableNetworkDebugLogs {
            TABLogger.debug("TABAI discovery failed: \(errors.joined(separator: " | "))")
        }
        return nil
    }

    private static func parsePaths(_ pathsObject: Any?) -> [String: TABAIPathInfo] {
        guard let pathsDict = pathsObject as? [String: Any] else { return [:] }
        var result: [String: TABAIPathInfo] = [:]

        for (path, value) in pathsDict {
            guard let methodsDict = value as? [String: Any] else { continue }
            var methods: [String] = []
            var tagsByMethod: [String: [String]] = [:]

            for (method, methodValue) in methodsDict {
                methods.append(method.lowercased())
                if let methodBody = methodValue as? [String: Any],
                   let tags = methodBody["tags"] as? [String] {
                    tagsByMethod[method.lowercased()] = tags
                }
            }

            result[path] = TABAIPathInfo(methods: methods, tagsByMethod: tagsByMethod)
        }

        return result
    }

    private static func parseAuthSchemes(_ componentsObject: Any?) -> [String] {
        guard let components = componentsObject as? [String: Any],
              let schemes = components["securitySchemes"] as? [String: Any] else {
            return []
        }

        var detected: [String] = []
        for (_, value) in schemes {
            if let scheme = value as? [String: Any] {
                if let type = scheme["type"] as? String {
                    detected.append(type)
                }
                if let schemeName = scheme["scheme"] as? String {
                    detected.append(schemeName)
                }
            }
        }
        return Array(Set(detected))
    }

    private static func buildBaseCandidates(from baseURL: URL, apiPrefix: String) -> [URL] {
        let trimmed = apiPrefix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard trimmed.isEmpty == false else { return [baseURL] }
        return [baseURL, baseURL.appendingPathComponent(trimmed, isDirectory: false)]
    }
}
