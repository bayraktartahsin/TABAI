import Foundation
import Combine
import LocalAuthentication
import AuthenticationServices
import UIKit

/// Provides the presentation anchor for ASWebAuthenticationSession
final class ASWebAuthContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = ASWebAuthContextProvider()
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

struct NetworkHealth: Equatable {
    var discoveryOK: Bool = false
    var lastModelsFetchOK: Bool = false
    var lastError: String?
    var openAPIURL: String?
    var baseAPIURL: String?
    var modelsEndpoint: String?
    var authMode: String?
}

struct FeatureFlags {
    var useTABAI: Bool = false
}

enum AppTab: Hashable {
    case chat
    case history
    case subscriptions
    case settings
}

@MainActor
final class AppEnvironment: ObservableObject {
    struct Session: Equatable {
        let token: String
        let email: String?
        let baseURL: URL?

        var isAuthenticated: Bool {
            token.isEmpty == false
        }
    }

    @Published private(set) var session: Session?
    @Published var featureFlags: FeatureFlags
    @Published private(set) var networkHealth: NetworkHealth = NetworkHealth()
    @Published private(set) var availableModels: [ModelCatalog.Model] = []
    @Published private(set) var currentUserProfile: UserProfile?
    let usageQuotaManager: UsageQuotaManager = .shared
    @Published var selectedModelId: String?
    @Published var selectedThreadId: String?
    @Published var selectedTab: AppTab = .chat
    @Published private(set) var isAuthenticating: Bool = false
    @Published var sessionValidationFailed: Bool = false
    @Published var biometricEnabled: Bool
    @Published private(set) var biometricAvailable: Bool
    @Published private(set) var biometricLabel: String
    @Published var requiresBiometricUnlock: Bool

    private static let biometricEnabledKey = "tai.biometricEnabled"
    private static let cachedModelsKey = "tai.cache.models"

    private let keychain: KeychainStore
    private let mockAuthService: AuthServiceProtocol
    private let mockChatService: ChatServiceProtocol
    private let mockModelsService: ModelsServiceProtocol
    private let mockSettingsService: SettingsServiceProtocol

    private let tabaiAuthService: AuthServiceProtocol
    private let tabaiChatService: ChatServiceProtocol
    let tabaiClient: TABAIClient
    private let tabaiModelsService: TABAIModelsService
    private let tabaiSettingsService: SettingsServiceProtocol
    private let tabaiBootstrapService: TABAIBootstrapService
    private let taiGenerationService: FalAIService
    private let tabaiStoreSyncService: StoreEntitlementSyncService

    init(
        keychain: KeychainStore,
        featureFlags: FeatureFlags
    ) {
        self.keychain = keychain
        self.featureFlags = featureFlags
        let biometricStatus = Self.detectBiometricStatus()
        self.biometricEnabled = UserDefaults.standard.bool(forKey: Self.biometricEnabledKey)
        self.biometricAvailable = biometricStatus.isAvailable
        self.biometricLabel = biometricStatus.label
        self.requiresBiometricUnlock = false

        let config = AppEnvironment.tabaiConfiguration()
        let client = TABAIClient(configuration: config) {
            keychain.readToken()
        }
        self.tabaiClient = client

        self.tabaiAuthService = TABAIAuthService(client: client)
        self.tabaiChatService = TABAIChatService(client: client)
        let modelsService = TABAIModelsService(client: client)
        self.tabaiModelsService = modelsService
        self.tabaiSettingsService = TABAISettingsService(client: client)
        self.tabaiBootstrapService = TABAIBootstrapService(client: client)
        self.taiGenerationService = FalAIService(client: client)
        self.tabaiStoreSyncService = StoreEntitlementSyncService(client: client)

        self.mockAuthService = MockAuthService()
        self.mockChatService = MockChatService()
        self.mockModelsService = MockModelsService()
        self.mockSettingsService = MockSettingsService()
        self.availableModels = Self.loadCachedModels()
        self.selectedModelId = self.availableModels.first?.id

        if let token = keychain.readToken() {
            self.session = Session(token: token, email: nil, baseURL: nil)
            if biometricEnabled && biometricAvailable {
                self.requiresBiometricUnlock = true
            }
            Task {
                await validateSession()
            }
        }

        self.featureFlags.useTABAI = true

        Task {
            await performDiscovery()
        }
    }

    var authService: AuthServiceProtocol {
        featureFlags.useTABAI ? tabaiAuthService : mockAuthService
    }

    var chatService: ChatServiceProtocol {
        featureFlags.useTABAI ? tabaiChatService : mockChatService
    }

    var modelsService: ModelsServiceProtocol {
        featureFlags.useTABAI ? tabaiModelsService : mockModelsService
    }

    var settingsService: SettingsServiceProtocol {
        featureFlags.useTABAI ? tabaiSettingsService : mockSettingsService
    }

    var storeSyncService: StoreEntitlementSyncService {
        tabaiStoreSyncService
    }

    var generationService: FalAIServiceProtocol {
        taiGenerationService
    }

    var effectiveCurrentPlanTier: PlanTier {
        currentUserProfile?.effectivePlanTier ?? .free
    }

    var effectiveCurrentEntitlement: EntitlementInfo? {
        currentUserProfile?.effectiveEntitlement
    }

    func setSession(token: String, email: String? = nil, baseURL: URL? = nil) {
        keychain.saveToken(token)
        session = Session(token: token, email: email, baseURL: baseURL)
        requiresBiometricUnlock = biometricEnabled && biometricAvailable
    }

    func signIn(email: String, password: String) async throws {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let token = try await authService.signIn(email: email, password: password)
        if AppConfig.enableNetworkDebugLogs {
            TABLogger.debug("TAI signin success for \(email)")
        }

        setSession(token: token, email: email)

        if AppConfig.enableNetworkDebugLogs {
            let cookieNames = HTTPCookieStorage.shared.cookies(for: AppEnvironment.tabaiConfiguration().baseURL)?.map(\.name) ?? []
            TABLogger.debug("TAI cookie persistence: \(cookieNames)")
        }

        do {
            let isValid = await authService.validateToken(token)
            if AppConfig.enableNetworkDebugLogs {
                TABLogger.debug("TAI auth/me success: \(isValid)")
            }
            guard isValid else {
                signOut()
                throw TABAIError.invalidResponse
            }
            let bootstrap = try await tabaiBootstrapService.fetchBootstrap()
            applyBootstrap(bootstrap)
        } catch {
            if AppConfig.enableNetworkDebugLogs {
                TABLogger.debug("TAI bootstrap failed after signin")
            }
            signOut()
            throw TABAIError.invalidResponse
        }
    }

    func signUp(email: String, password: String) async throws {
        let url = tabaiClient.baseURL.appendingPathComponent("api/auth/signup")
        let body = try JSONSerialization.data(withJSONObject: [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            "password": password
        ])
        let (_, response) = try await tabaiClient.requestRaw(method: "POST", url: url, body: body)
        guard response.statusCode == 200 || response.statusCode == 201 else {
            throw TABAIError.invalidResponse
        }
    }

    func signInWithGoogle() async throws {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        // Open Google OAuth via backend redirect with platform=ios
        var urlComponents = URLComponents(url: tabaiClient.baseURL.appendingPathComponent("api/auth/google"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "platform", value: "ios")]
        guard let authURL = urlComponents.url else { throw TABAIError.invalidResponse }

        let callbackScheme = "tabai"

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: TABAIError.invalidResponse)
                }
            }
            session.presentationContextProvider = ASWebAuthContextProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }

        // Parse callback URL for session token and email
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw TABAIError.invalidResponse
        }
        let tokenParam = components.queryItems?.first(where: { $0.name == "token" })?.value
        let emailParam = components.queryItems?.first(where: { $0.name == "email" })?.value

        // Use session token from callback if available, otherwise fall back to cookie-based auth
        let sessionToken = (tokenParam != nil && !tokenParam!.isEmpty) ? tokenParam! : taiCookieSessionSentinel
        setSession(token: sessionToken, email: emailParam)

        do {
            let bootstrap = try await tabaiBootstrapService.fetchBootstrap()
            applyBootstrap(bootstrap)
        } catch {
            signOut()
            throw TABAIError.invalidResponse
        }
    }

    func signInWithApple(identityToken: String, fullName: PersonNameComponents?, email: String?) async throws {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        // Apple only provides name/email on FIRST sign-in — persist locally
        if let fullName {
            var name = ""
            if let given = fullName.givenName { name += given }
            if let family = fullName.familyName { name += (name.isEmpty ? "" : " ") + family }
            if !name.isEmpty {
                UserDefaults.standard.set(name, forKey: "tai.apple.displayName")
            }
        }

        // Send the Apple identity token to backend for verification
        let url = tabaiClient.baseURL.appendingPathComponent("api/auth/apple")
        var body: [String: Any] = ["identityToken": identityToken]
        if let email { body["email"] = email }
        // Use stored name if Apple didn't provide one this time (subsequent sign-ins)
        let storedName = UserDefaults.standard.string(forKey: "tai.apple.displayName")
        if let name = storedName, !name.isEmpty {
            body["displayName"] = name
        }
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await tabaiClient.requestRaw(method: "POST", url: url, body: jsonData)

        guard response.statusCode == 200 else {
            // Surface backend error message if available
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMsg = json["error"] as? String {
                throw TABAIError.serverError(errorMsg)
            }
            throw TABAIError.invalidResponse
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let userDict = json["user"] as? [String: Any],
              let userEmail = userDict["email"] as? String else {
            throw TABAIError.invalidResponse
        }

        setSession(token: taiCookieSessionSentinel, email: userEmail)

        do {
            let bootstrap = try await tabaiBootstrapService.fetchBootstrap()
            applyBootstrap(bootstrap)
        } catch {
            signOut()
            throw TABAIError.invalidResponse
        }
    }

    func signOut() {
        if let token = session?.token {
            Task { [authService] in
                await authService.signOut(token: token)
            }
        }
        keychain.deleteToken()
        session = nil
        availableModels = []
        currentUserProfile = nil
        selectedModelId = nil
        requiresBiometricUnlock = false
        selectedThreadId = nil
        selectedTab = .chat
        PersistenceController.shared.reset()
        UserDefaults.standard.removeObject(forKey: Self.cachedModelsKey)
    }

    func setBiometricPreference(enabled: Bool) async -> Bool {
        guard biometricAvailable else {
            biometricEnabled = false
            UserDefaults.standard.set(false, forKey: Self.biometricEnabledKey)
            return false
        }
        if enabled {
            let granted = await authenticateWithBiometrics(reason: "Enable \(biometricLabel) for TAI")
            biometricEnabled = granted
            UserDefaults.standard.set(granted, forKey: Self.biometricEnabledKey)
            return granted
        }
        biometricEnabled = false
        requiresBiometricUnlock = false
        UserDefaults.standard.set(false, forKey: Self.biometricEnabledKey)
        return true
    }

    func unlockWithBiometrics() async -> Bool {
        guard biometricEnabled, biometricAvailable else {
            requiresBiometricUnlock = false
            return true
        }
        let granted = await authenticateWithBiometrics(reason: "Unlock TAI")
        requiresBiometricUnlock = !granted
        return granted
    }

    func refreshConversations() async {
        guard session?.isAuthenticated == true, !isAuthenticating else { return }
        do {
            let remote = try await chatService.fetchChats()
            PersistenceController.shared.upsertThreads(remote)
        } catch {
            if AppConfig.enableNetworkDebugLogs {
                TABLogger.debug("TAI refresh failed; using cached data")
            }
        }
    }

    func refreshModels() async {
        guard session?.isAuthenticated == true, !isAuthenticating else { return }
        do {
            let models = try await modelsService.fetchModels()
            availableModels = models
            Self.saveCachedModels(models)
            if selectedModelId == nil || models.contains(where: { $0.id == selectedModelId }) == false {
                selectedModelId = models.first(where: { $0.canAccess })?.id ?? models.first?.id
            }
            if let endpoint = tabaiModelsService.lastEndpoint?.absoluteString {
                networkHealth.modelsEndpoint = endpoint
            }
            networkHealth.lastModelsFetchOK = true
        } catch {
            if AppConfig.enableNetworkDebugLogs {
                TABLogger.debug("TAI models fetch failed: \(error)")
            }
            networkHealth.lastModelsFetchOK = false
            networkHealth.lastError = "Models fetch failed: \(error)"
        }
    }

    func refreshBootstrapState() async {
        guard session?.isAuthenticated == true, !isAuthenticating else { return }
        do {
            let bootstrap = try await tabaiBootstrapService.fetchBootstrap()
            applyBootstrap(bootstrap)
        } catch {
            if AppConfig.enableNetworkDebugLogs {
                TABLogger.debug("TAI bootstrap refresh failed: \(error)")
            }
        }
    }

    func reconcileStoreEntitlement(_ syncResult: StoreSyncResult) {
        guard let profile = currentUserProfile else { return }
        let latestEntitlement = syncResult.entitlement ?? syncResult.latestEntitlement
        guard let latestEntitlement else { return }
        currentUserProfile = profile.updatingEntitlement(latestEntitlement)
    }

    private func performDiscovery() async {
        let baseURL = AppEnvironment.tabaiConfiguration().baseURL
        if AppConfig.enableNetworkDebugLogs {
            TABLogger.debug("TAI base URL: \(baseURL.absoluteString)")
            TABLogger.debug("TAI auth mode: \(AppConfig.authMode.rawValue)")
        }
        networkHealth.discoveryOK = true
        networkHealth.openAPIURL = nil
        networkHealth.baseAPIURL = baseURL.absoluteString
        networkHealth.lastError = nil
        networkHealth.authMode = AppConfig.authMode.rawValue
        featureFlags.useTABAI = true
    }

    func retrySessionValidation() async {
        sessionValidationFailed = false
        await validateSession()
    }

    private func validateSession() async {
        guard session?.token != nil else { return }

        // Step 1: Validate token — only sign out on explicit invalidity (401)
        let isValid = await authService.validateToken(session?.token ?? "")
        if AppConfig.enableNetworkDebugLogs {
            TABLogger.debug("TAI auth/me success for restored session: \(isValid)")
        }
        guard isValid else {
            // Token is explicitly invalid (server said 401) — sign out
            signOut()
            return
        }

        // Step 2: Bootstrap with retry (3 attempts, 2s delay)
        var lastError: Error?
        for attempt in 1...3 {
            do {
                let bootstrap = try await tabaiBootstrapService.fetchBootstrap()
                if AppConfig.enableNetworkDebugLogs {
                    TABLogger.debug("TAI bootstrap success for restored session (attempt \(attempt))")
                }
                applyBootstrap(bootstrap)
                sessionValidationFailed = false
                return
            } catch {
                lastError = error
                if AppConfig.enableNetworkDebugLogs {
                    TABLogger.debug("TAI bootstrap attempt \(attempt)/3 failed: \(error)")
                }
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }

        // All retries exhausted — show retry banner, do NOT sign out
        if AppConfig.enableNetworkDebugLogs {
            TABLogger.debug("TAI bootstrap failed after 3 attempts: \(String(describing: lastError))")
        }
        sessionValidationFailed = true
    }

    private static func tabaiConfiguration() -> TABAIConfiguration {
        let baseURLString = AppConfig.taiAPIBaseURL
        guard let url = URL(string: baseURLString), baseURLString.isEmpty == false else {
            let fallback = URL(string: "https://ai.gravitilabs.com") ?? URL(fileURLWithPath: "/")
            return TABAIConfiguration(baseURL: fallback, apiKey: nil, cookieAuthEnabled: false)
        }
        let cookieEnabled = true
        return TABAIConfiguration(
            baseURL: url,
            apiKey: AppConfig.tabaiAPIKey,
            cookieAuthEnabled: cookieEnabled
        )
    }

    private func authenticateWithBiometrics(reason: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let context = LAContext()
            var error: NSError?
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                continuation.resume(returning: false)
                return
            }
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    private static func detectBiometricStatus() -> (isAvailable: Bool, label: String) {
        let context = LAContext()
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let label: String
        switch context.biometryType {
        case .faceID:
            label = "Face ID"
        case .touchID:
            label = "Touch ID"
        default:
            label = "Biometrics"
        }
        return (available, label)
    }

    private func applyBootstrap(_ payload: TABAIBootstrapPayload) {
        currentUserProfile = payload.user
        availableModels = payload.models
        Self.saveCachedModels(payload.models)
        if selectedModelId == nil || payload.models.contains(where: { $0.id == selectedModelId }) == false {
            selectedModelId = payload.models.first(where: { $0.canAccess })?.id ?? payload.models.first?.id
        }
        PersistenceController.shared.upsertThreads(payload.chats)
    }

    private static func loadCachedModels() -> [ModelCatalog.Model] {
        guard let data = UserDefaults.standard.data(forKey: cachedModelsKey),
              let models = try? JSONDecoder().decode([ModelCatalog.Model].self, from: data),
              !models.isEmpty else {
            return []
        }
        if AppConfig.enableNetworkDebugLogs {
            TABLogger.debug("TAI loaded \(models.count) cached models from UserDefaults")
        }
        return models
    }

    private static func saveCachedModels(_ models: [ModelCatalog.Model]) {
        if let data = try? JSONEncoder().encode(models) {
            UserDefaults.standard.set(data, forKey: cachedModelsKey)
        }
    }
}
