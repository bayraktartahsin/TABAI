import Foundation

enum AppConfig {
    enum AuthMode: String {
        case apiKey
        case cookie
        case signin
    }

    private struct BundledConfig: Codable {
        let taiAPIBaseURL: String?
        let taiBaseURL: String?
        let productionBaseURL: String?
        let localDevelopmentBaseURL: String?
        let iosProductIdStarter: String?
        let iosProductIdPro: String?
        let iosProductIdPower: String?
        let iosProductIdStarterYearly: String?
        let iosProductIdProYearly: String?
        let iosProductIdPowerYearly: String?
        let tabaiBaseURL: String?
        let tabaiAPIPrefix: String?
        let authMode: String?
        let tabaiCookieAuthEnabled: Bool?
        let enableDiscovery: Bool?
        let requestTimeoutSeconds: Double?
    }

    private static let bundledConfig: BundledConfig? = loadBundledConfig()

    private static var allowsLocalRuntimeOverrides: Bool {
        #if DEBUG
        return true
        #else
        return infoPlistBool(forKey: "TAI_ALLOW_LOCAL_RUNTIME_OVERRIDES") ?? false
        #endif
    }

    static var taiAPIBaseURL: String {
        if let value = infoPlistString(forKey: "TAI_API_BASE_URL"), value.isEmpty == false {
            return value
        }
        if let value = infoPlistString(forKey: "TAI_BASE_URL"), value.isEmpty == false {
            return value
        }
        if let value = infoPlistString(forKey: "OPENWEBUI_BASE_URL"), value.isEmpty == false {
            return value
        }
        if allowsLocalRuntimeOverrides,
           let value = UserDefaults.standard.string(forKey: "tai.baseURLOverride"), value.isEmpty == false {
            return value
        }
        if let value = bundledConfig?.taiBaseURL, value.isEmpty == false {
            return value
        }
        if let value = bundledConfig?.productionBaseURL, value.isEmpty == false {
            return value
        }
        if let value = bundledConfig?.tabaiBaseURL, value.isEmpty == false {
            return value
        }
        return "https://ai.gravitilabs.com"
    }

    static var tabaiBaseURL: String {
        taiAPIBaseURL
    }

    static var tabaiAPIPrefix: String {
        if let value = infoPlistString(forKey: "OPENWEBUI_API_PREFIX") {
            return value
        }
        if let value = bundledConfig?.tabaiAPIPrefix {
            return value
        }
        return ""
    }

    static var authMode: AuthMode {
        if let value = infoPlistString(forKey: "OPENWEBUI_AUTH_MODE"),
           let mode = AuthMode(rawValue: value.lowercased()) {
            return mode
        }
        if let value = bundledConfig?.authMode,
           let mode = AuthMode(rawValue: value.lowercased()) {
            return mode
        }
        return .signin
    }

    static let tabaiAPIKey: String? = infoPlistString(forKey: "OPENWEBUI_API_KEY")

    static var tabaiCookieAuthEnabled: Bool {
        if let value = infoPlistBool(forKey: "OPENWEBUI_COOKIE_AUTH") {
            return value
        }
        if let value = bundledConfig?.tabaiCookieAuthEnabled {
            return value
        }
        return authMode == .signin || authMode == .cookie
    }

    static var enableDiscovery: Bool {
        if let value = infoPlistBool(forKey: "OPENWEBUI_ENABLE_DISCOVERY") {
            return value
        }
        if let value = bundledConfig?.enableDiscovery {
            return value
        }
        return true
    }

    static var requestTimeoutSeconds: TimeInterval {
        if let value = infoPlistDouble(forKey: "OPENWEBUI_TIMEOUT") {
            return value
        }
        if let value = bundledConfig?.requestTimeoutSeconds {
            return value
        }
        return 30
    }

    static var streamTimeoutSeconds: TimeInterval {
        max(180, requestTimeoutSeconds)
    }

    static var iosSubscriptionProductMap: [PlanTier: String] {
        // Primary production configuration point for App Store Connect product IDs.
        // Release/TestFlight builds ignore local UserDefaults overrides unless explicitly allowed.
        // Bundled ServerConfig.json is the release-safe override layer before hardcoded defaults.
        let starter = localProductIdOverride(forKey: "tai.productId.starter")
            ?? infoPlistString(forKey: "TAI_IOS_PRODUCT_ID_STARTER")
            ?? bundledConfig?.iosProductIdStarter
            ?? "com.tai.starter.monthly"
        let pro = localProductIdOverride(forKey: "tai.productId.pro")
            ?? infoPlistString(forKey: "TAI_IOS_PRODUCT_ID_PRO")
            ?? bundledConfig?.iosProductIdPro
            ?? "com.tai.pro.monthly"
        let power = localProductIdOverride(forKey: "tai.productId.power")
            ?? infoPlistString(forKey: "TAI_IOS_PRODUCT_ID_POWER")
            ?? bundledConfig?.iosProductIdPower
            ?? "com.tai.power.monthly"
        return [
            .starter: starter,
            .pro: pro,
            .power: power,
        ]
    }

    static var iosSubscriptionYearlyProductMap: [PlanTier: String] {
        let starter = localProductIdOverride(forKey: "tai.productId.starter.yearly")
            ?? infoPlistString(forKey: "TAI_IOS_PRODUCT_ID_STARTER_YEARLY")
            ?? bundledConfig?.iosProductIdStarterYearly
            ?? inferYearlyProductId(from: iosSubscriptionProductMap[.starter])
            ?? "com.tai.starter.yearly"
        let pro = localProductIdOverride(forKey: "tai.productId.pro.yearly")
            ?? infoPlistString(forKey: "TAI_IOS_PRODUCT_ID_PRO_YEARLY")
            ?? bundledConfig?.iosProductIdProYearly
            ?? inferYearlyProductId(from: iosSubscriptionProductMap[.pro])
            ?? "com.tai.pro.yearly"
        let power = localProductIdOverride(forKey: "tai.productId.power.yearly")
            ?? infoPlistString(forKey: "TAI_IOS_PRODUCT_ID_POWER_YEARLY")
            ?? bundledConfig?.iosProductIdPowerYearly
            ?? inferYearlyProductId(from: iosSubscriptionProductMap[.power])
            ?? "com.tai.power.yearly"
        return [
            .starter: starter,
            .pro: pro,
            .power: power,
        ]
    }

    static var enableStoreKitDebugLogs: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static var discoveredOpenAPIURL: String? {
        get { UserDefaults.standard.string(forKey: "openwebui.discoveredOpenAPIURL") }
        set { UserDefaults.standard.setValue(newValue, forKey: "openwebui.discoveredOpenAPIURL") }
    }

    static var enableNetworkDebugLogs: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private static func infoPlistString(forKey key: String) -> String? {
        Bundle.main.infoDictionary?[key] as? String
    }

    private static func infoPlistBool(forKey key: String) -> Bool? {
        if let value = Bundle.main.infoDictionary?[key] as? Bool {
            return value
        }
        if let value = Bundle.main.infoDictionary?[key] as? String {
            return (value as NSString).boolValue
        }
        return nil
    }

    private static func infoPlistDouble(forKey key: String) -> Double? {
        if let value = Bundle.main.infoDictionary?[key] as? Double {
            return value
        }
        if let value = Bundle.main.infoDictionary?[key] as? String {
            return Double(value)
        }
        return nil
    }

    private static func localProductIdOverride(forKey key: String) -> String? {
        guard allowsLocalRuntimeOverrides else { return nil }
        guard let value = UserDefaults.standard.string(forKey: key), value.isEmpty == false else {
            return nil
        }
        return value
    }

    private static func inferYearlyProductId(from productId: String?) -> String? {
        guard let productId, productId.isEmpty == false else { return nil }
        if productId.hasSuffix(".monthly") {
            return String(productId.dropLast(".monthly".count)) + ".yearly"
        }
        if productId.contains("monthly") {
            return productId.replacingOccurrences(of: "monthly", with: "yearly")
        }
        return nil
    }

    private static func loadBundledConfig() -> BundledConfig? {
        guard let url = Bundle.main.url(forResource: "ServerConfig", withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(BundledConfig.self, from: data)
    }
}
