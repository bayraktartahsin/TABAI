# App Store Subscription Mapping (iOS)

This app uses StoreKit 2 for subscription purchase/restore and the backend at https://ai.gravitilabs.com as entitlement source of truth.

## 1) Single place for iOS product IDs

Primary config location:
- `AppConfig.iosSubscriptionProductMap` in `Core/Config/AppConfig.swift`
- Release-safe bundled config values live in `Core/Config/ServerConfig.json`

Override priority:
1. UserDefaults (DEBUG or explicitly allowed local override builds only)
- `tai.productId.starter`
- `tai.productId.pro`
- `tai.productId.power`
2. Info.plist / build settings
- `TAI_IOS_PRODUCT_ID_STARTER`
- `TAI_IOS_PRODUCT_ID_PRO`
- `TAI_IOS_PRODUCT_ID_POWER`
3. `ServerConfig.json`
- `iosProductIdStarter`
- `iosProductIdPro`
- `iosProductIdPower`
4. Built-in defaults
- `com.tai.starter.monthly`
- `com.tai.pro.monthly`
- `com.tai.power.monthly`

## 2) Backend mapping alignment

Backend expects map keys as `apple:<productId>` in `TAI_STORE_PRODUCT_PLAN_MAP`.

Example:

```json
{
  "apple:com.tai.starter.monthly": "starter",
  "apple:com.tai.pro.monthly": "pro",
  "apple:com.tai.power.monthly": "power"
}
```

The app also exposes this mapping summary in `SubscriptionPlanCatalog.backendPlanMappingGuide`.

## 3) First TestFlight subscription test flow

1. Upload a new iOS build to App Store Connect from the `TAI` scheme.
2. Add an internal TestFlight tester to that build.
3. Install the TestFlight build on an iPhone or iPad.
4. Sign in with a real TAI app account.
5. Open the Plans tab.
6. Buy Starter.
7. Wait for the purchase result and backend sync status message.
8. Verify the current plan updates and previously locked models refresh.
9. Tap Restore Purchases and verify the restore path also completes cleanly.

## 4) Tester checklist

1. Use a TestFlight build, not a local Xcode StoreKit configuration.
2. Sign in to the app before opening Plans so backend sync can attach the purchase to the correct account.
3. Confirm Starter loads with product ID `com.tai.starter.monthly`.
4. After purchase, verify the app reports success, pending validation, or a backend retry instruction.
5. Confirm Settings and Plans show the updated plan and entitlement source/status.
6. Open Chat and confirm locked models refresh for the new access level.
7. Test Restore Purchases on the same Apple ID used for the original purchase.

## 5) Release notes

- TestFlight and Release builds ignore local `tai.baseURLOverride` and `tai.productId.*` UserDefaults overrides unless `TAI_ALLOW_LOCAL_RUNTIME_OVERRIDES` is explicitly enabled.
- Production backend source of truth remains `https://ai.gravitilabs.com`.
- Product IDs remain:
  - `com.tai.starter.monthly`
  - `com.tai.pro.monthly`
  - `com.tai.power.monthly`

## 6) Debug observability

In DEBUG builds, StoreKit and sync flows print minimal logs via `AppConfig.enableStoreKitDebugLogs`.
