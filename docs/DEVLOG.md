# DEVLOG

## 2026-02-19

- Initialized full hard reset workflow for iOS app.
- Deleted previous iOS sources under `ios/TAIApp/Sources`.
- Created new architecture folders under:
  - `App`
  - `Core` (DesignSystem, Localization, Keychain, Haptics, Routing, Networking scaffold)
  - `Features` (Auth, Chat, Voice, History, Settings)
  - `Services`
  - `Persistence`
  - `Models`
- Added localization resources:
  - `ios/TAIApp/Resources/en.lproj/Localizable.strings`
  - `ios/TAIApp/Resources/tr.lproj/Localizable.strings`
- Added local model catalog:
  - `ios/TAIApp/Resources/ModelCatalog.json`

### Milestone 0
- Recreated app entry, environment container, theme + locale wiring.
- App launch now routes Sign In vs Main Tabs based on keychain token.

### Milestone 1
- Implemented local sign-in only (no sign-up).
- Added email/password validation and error states.
- Stored mock session token/email in Keychain.
- Added sign-out path clearing session from Keychain.

### Milestone 2
- Built new tab shell:
  - Chat
  - History
  - Profile/Settings
- Added router for cross-tab conversation opening.

### Milestone 3
- Implemented native chat screen:
  - model pill selector
  - new chat action
  - markdown-capable assistant rendering
  - safe-area composer pinned above keyboard area
- Added localized starter prompt cards for EN/TR.

### Milestone 4
- Implemented `MockChatService` token streaming.
- Added stop generating, regenerate, retry, copy, and edit-user-message/rerun flow.

### Milestone 5
- Implemented local persistence store for conversation history (JSON-backed).
- Added search, pin/unpin, rename, delete in History.
- Added open-from-history routing to active chat.

### Milestone 6
- Added attachment scaffolding:
  - Photo Library (`PhotosPicker`)
  - Camera (`UIImagePickerController` wrapper)
  - Files (`fileImporter`)
- Added attachment chips above composer and local path capture.

### Milestone 7
- Added full voice session screen:
  - animated orb
  - start/stop/mute/end controls
  - mock transcript stream
  - transcript persistence into conversation
  - local TTS playback via `AVSpeechSynthesizer`

### Milestone 8
- Added settings:
  - Theme (System/Light/Dark)
  - Language (EN/TR)
  - Default model selection
  - Voice selection
  - About version/build

### Milestone 9
- Completed UI polish pass:
  - semantic design tokens
  - reusable premium components
  - haptics for key actions
- Rebuilt project and validated simulator build success using:
  - `xcodegen generate`
  - `xcodebuild ... -derivedDataPath /tmp/TAIAppDerivedData`

### Milestone 10
- Not started by instruction.

## 2026-02-19 (UI Emergency Fix: Sign-In Edge-to-Edge + Localization)

- Root causes addressed:
  - Localization keys were visible because lookup had no safe fallback.
  - Sign-in layout still had a constrained centered form presentation.

- Implemented safe localization layer:
  - Added `/Users/bayraktar/Documents/New Apps/TAI/ios/TAIApp/Sources/Core/Localization/Localizer.swift`
  - Updated `/Users/bayraktar/Documents/New Apps/TAI/ios/TAIApp/Sources/Core/Localization/L10n.swift` to use Localizer fallback logic:
    - Try selected language (`tai.language`)
    - Fallback to English
    - Fallback to provided literal or prettified key (never raw key)

- Updated localization resources:
  - `/Users/bayraktar/Documents/New Apps/TAI/ios/TAIApp/Resources/en.lproj/Localizable.strings`
  - `/Users/bayraktar/Documents/New Apps/TAI/ios/TAIApp/Resources/tr.lproj/Localizable.strings`
  - Added `common.continue` and `common.cancel`
  - Updated password rule text to 8 chars in EN/TR

- Rebuilt Sign-In UI to full-screen premium glass:
  - `/Users/bayraktar/Documents/New Apps/TAI/ios/TAIApp/Sources/Features/Auth/SignInView.swift`
  - Full-screen gradient + blurred light blobs + glass panel (`.ultraThinMaterial`)
  - Removed centered-card hard constraints causing letterboxing behavior
  - Added layered border/shadow depth
  - Added keyboard observer + bottom safe padding to keep CTA reachable on small screens
  - Added touch-to-dismiss keyboard and haptic taps

- Edge-to-edge root hardening:
  - `/Users/bayraktar/Documents/New Apps/TAI/ios/TAIApp/Sources/App/AppRootView.swift`
  - Ensured root stack/background ignores safe areas

- Auth validation alignment:
  - `/Users/bayraktar/Documents/New Apps/TAI/ios/TAIApp/Sources/App/SessionManager.swift`
  - Password minimum updated to 8 chars to match UI copy.

- Build verification:
  - Regenerated project with `xcodegen generate`
  - Simulator build succeeded via:
    - `xcodebuild -project ios/TAIApp/TAIApp.xcodeproj -scheme TAIApp -sdk iphonesimulator -configuration Debug build -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/TAIAppDerivedData`

## 2026-02-19 (Fullscreen Constraint Fix)

- Root cause:
  - `SignInView` content used content-sized constraints (`minHeight` tied to `UIScreen.main.bounds`) inside `ScrollView`, which caused non-deterministic layout sizing and visible black regions on some simulator/device combinations.
  - Root host used `Group` with background modifiers instead of an explicit full-screen container frame.

- Fixes applied (visual style preserved):
  - `AppRootView` moved to a root `ZStack` with explicit:
    - `.frame(maxWidth: .infinity, maxHeight: .infinity)`
    - background layer pinned to full screen.
  - `SignInView` root `ZStack` and `ScrollView` now both enforce:
    - `.frame(maxWidth: .infinity, maxHeight: .infinity)`
  - Removed content-sized constraints from sign-in fields and removed:
    - `.frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.9)`
  - Background remains outside `ScrollView` and uses `.ignoresSafeArea()`.

- Result:
  - Full-screen edge-to-edge sign-in background with no top/bottom black bars caused by layout constraints.
