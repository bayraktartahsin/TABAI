import Foundation
import StoreKit
import Combine

@MainActor
final class StoreKitSubscriptionManager: ObservableObject {
    enum PurchaseState: Equatable {
        case idle
        case loadingProducts
        case purchasing(PlanTier)
        case restoring
        case cancelled(String)
        case success(String)
        case pending(String)
        case failed(String)
    }

    @Published private(set) var productsById: [String: Product] = [:]
    @Published private(set) var localActiveProductIds: Set<String> = []
    @Published private(set) var unavailableProductIds: [String] = []
    @Published private(set) var state: PurchaseState = .idle
    @Published private(set) var lastSyncDebugDetails: String?

    var isLoadingProducts: Bool {
        if case .loadingProducts = state { return true }
        return false
    }

    var isRestoring: Bool {
        if case .restoring = state { return true }
        return false
    }

    func isPurchasing(_ tier: PlanTier) -> Bool {
        if case .purchasing(let activeTier) = state {
            return activeTier == tier
        }
        return false
    }

    private var syncService: StoreEntitlementSyncService?
    private var onPostSyncRefresh: ((StoreSyncResult) async -> Void)?

    var plans: [SubscriptionPlan] {
        SubscriptionPlanCatalog.plans
    }

    func configure(syncService: StoreEntitlementSyncService, onPostSyncRefresh: @escaping (StoreSyncResult) async -> Void) {
        self.syncService = syncService
        self.onPostSyncRefresh = onPostSyncRefresh
    }

    func loadProducts() async {
        state = .loadingProducts
        lastSyncDebugDetails = nil
        do {
            let productIds = plans.map(\.productId)
            let loaded = try await Product.products(for: productIds)
            productsById = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
            unavailableProductIds = productIds.filter { productsById[$0] == nil }
            if AppConfig.enableStoreKitDebugLogs {
                print("TAI StoreKit products loaded: \(productsById.keys.sorted())")
                if unavailableProductIds.isEmpty == false {
                    print("TAI StoreKit unavailable product IDs: \(unavailableProductIds)")
                }
            }
            await refreshLocalEntitlements()
            if productsById.isEmpty {
                state = .failed("No subscription products are currently available.")
            } else {
                state = .idle
            }
        } catch {
            if AppConfig.enableStoreKitDebugLogs {
                print("TAI StoreKit load failed: \(error)")
            }
            state = .failed("Unable to load subscription products.")
        }
    }

    func purchase(plan: SubscriptionPlan) async {
        lastSyncDebugDetails = nil
        if isLoadingProducts {
            lastSyncDebugDetails = productLoadDebugDetails(requestedPlan: plan)
            state = .failed("\(plan.title) is still loading from the App Store. Wait a moment and try again.")
            return
        }
        if unavailableProductIds.contains(plan.productId) {
            lastSyncDebugDetails = productLoadDebugDetails(requestedPlan: plan)
            state = .failed("\(plan.title) is unavailable for this App Store account or TestFlight build.")
            return
        }
        guard let product = productsById[plan.productId] else {
            lastSyncDebugDetails = productLoadDebugDetails(requestedPlan: plan)
            state = .failed("\(plan.title) has not loaded from the App Store yet.")
            return
        }
        state = .purchasing(plan.planTier)
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    let sync = try await syncVerifiedTransaction(transaction)
                    await transaction.finish()
                    lastSyncDebugDetails = syncDebugDetails(sync, transaction: transaction)
                    if AppConfig.enableStoreKitDebugLogs {
                        print("TAI sync result: provider=\(sync.provider) state=\(sync.verificationState) code=\(sync.code)")
                    }
                    if sync.verificationState == "verified" && sync.isEntitlementActive {
                        state = .success("Purchase synced. Your plan is now \(SubscriptionPlanCatalog.displayName(for: sync.entitlement?.planTier ?? plan.planTier)).")
                    } else if sync.verificationState == "verified" {
                        state = .failed("Purchase verified, but backend did not return an active entitlement. \(sync.code): \(sync.message)")
                    } else if sync.verificationState == "pending_validation" {
                        state = .pending("Purchase received by Apple. Backend returned \(sync.code): \(sync.message)")
                    } else {
                        state = .failed("Purchase completed in the App Store, but backend returned \(sync.code): \(sync.message)")
                    }
                case .unverified:
                    state = .failed("Purchase could not be verified by StoreKit.")
                }
            case .pending:
                state = .pending("Purchase is pending approval from Apple.")
            case .userCancelled:
                state = .cancelled("Purchase cancelled.")
            @unknown default:
                state = .failed("Purchase result is not recognized.")
            }
        } catch {
            lastSyncDebugDetails = StoreEntitlementSyncService.debugSummary(for: error)
            if AppConfig.enableStoreKitDebugLogs {
                print("TAI purchase failed: \(error)")
            }
            state = .failed(StoreEntitlementSyncService.userFacingMessage(for: error))
        }
    }

    func restorePurchases() async {
        state = .restoring
        lastSyncDebugDetails = nil
        do {
            try await AppStore.sync()
        } catch {
            if AppConfig.enableStoreKitDebugLogs {
                print("TAI AppStore.sync() failed: \(error)")
            }
            state = .failed("Could not reach the App Store. Check your connection and try again.")
            return
        }

        await refreshLocalEntitlements()

        var syncedAny = false
        var pendingAny = false
        var syncErrorMessages: [String] = []
        var syncDebugMessages: [String] = []
        var foundAny = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard plans.contains(where: { $0.productId == transaction.productID }) else { continue }
            foundAny = true
            do {
                let sync = try await syncVerifiedTransaction(transaction)
                if let debug = syncDebugDetails(sync, transaction: transaction) {
                    syncDebugMessages.append(debug)
                }
                if sync.verificationState == "verified" { syncedAny = true }
                else if sync.verificationState == "pending_validation" { pendingAny = true }
                else { syncErrorMessages.append("\(sync.code): \(sync.message)") }
            } catch {
                let message = StoreEntitlementSyncService.userFacingMessage(for: error)
                syncErrorMessages.append(message)
                if let debug = StoreEntitlementSyncService.debugSummary(for: error) {
                    syncDebugMessages.append(debug)
                }
                if AppConfig.enableStoreKitDebugLogs {
                    print("TAI backend sync failed during restore for \(transaction.productID): \(error)")
                }
            }
        }

        lastSyncDebugDetails = syncDebugMessages.isEmpty ? nil : syncDebugMessages.joined(separator: "\n")

        if syncedAny {
            state = .success("Restored purchases and synced with backend.")
        } else if pendingAny {
            state = .pending("Purchase restored from Apple. Backend returned pending validation.")
        } else if foundAny {
            let detail = syncErrorMessages.first ?? "Backend could not confirm the purchase."
            state = .failed("Purchase found but backend sync failed: \(detail)")
        } else {
            state = .cancelled("No active purchases were found on this Apple ID.")
        }
    }

    func refreshLocalEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if plans.contains(where: { $0.productId == transaction.productID }) {
                active.insert(transaction.productID)
            }
        }
        localActiveProductIds = active
    }

    private func syncVerifiedTransaction(_ transaction: Transaction) async throws -> StoreSyncResult {
        guard let syncService else {
            throw NSError(domain: "StoreSyncServiceMissing", code: 1)
        }
        let syncResult = try await syncService.syncApple(transaction: transaction)
        await refreshLocalEntitlements()
        if let onPostSyncRefresh {
            await onPostSyncRefresh(syncResult)
        }
        return syncResult
    }

    private func syncDebugDetails(_ sync: StoreSyncResult, transaction: Transaction) -> String? {
        let parts: [String?] = [
            "tx=\(transaction.id)",
            "product=\(transaction.productID)",
            "state=\(sync.verificationState)",
            "code=\(sync.code)",
            sync.debugSummary
        ]
        let value = parts.compactMap { $0 }.joined(separator: " | ")
        return value.isEmpty ? nil : value
    }

    private func productLoadDebugDetails(requestedPlan: SubscriptionPlan) -> String {
        [
            "requestedPlan=\(requestedPlan.planTier.rawValue)",
            "requestedProduct=\(requestedPlan.productId)",
            "loadedProducts=\(productsById.keys.sorted().joined(separator: ","))",
            "unavailableProducts=\(unavailableProductIds.sorted().joined(separator: ","))"
        ]
        .joined(separator: " | ")
    }
}
