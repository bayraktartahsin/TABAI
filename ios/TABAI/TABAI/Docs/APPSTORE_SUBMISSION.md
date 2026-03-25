# TABAI — App Store Submission Package

## 1. App Store Metadata

### App Name (30 chars max)
**TABAI - AI Chat Assistant** (26 chars)

Alt options if taken:
- TABAI Assistant - AI Chat (25 chars)
- TABAI: Ask AI Anything (22 chars)

### Subtitle (30 chars max)
**GPT, Claude, Gemini & More** (28 chars)

### Category
Primary: **Productivity**
Secondary: **Utilities**

### Description (4000 chars max)

TABAI gives you access to the world's best AI models in one fast, private app.

Ask anything. Get accurate answers from GPT-5, Claude Opus, Gemini Pro, DeepSeek R1, Grok, and 40+ more models — all in a clean, distraction-free interface.

**WHY TABAI?**

- One app, every top AI model. No switching between apps.
- Clean, fast interface designed for focus.
- Private by design. No tracking, no ads, no data selling.

**FREE TIER — NO CREDIT CARD**
Start with 8 powerful models at no cost:
- Llama 3.3 70B, Gemma 3, Qwen3, Mistral Small, and more
- Unlimited conversations
- Full chat history

**STARTER PLAN**
Unlock everyday models like GPT-4o Mini, Claude Haiku, Gemini Flash, and DeepSeek V3.

**PRO PLAN**
Access premium models: GPT-4o, GPT-4.1, Claude Sonnet 4.5, Gemini 2.5 Pro, DeepSeek R1, and advanced reasoning models like O3 Mini and O4 Mini.

**POWER PLAN**
Everything unlocked: Claude Opus 4.5, GPT-5, O1, O3, O3 Pro, Grok 4, and more flagship models.

**FEATURES**
- Voice input with speech recognition in 16+ languages
- Switch models instantly mid-conversation
- Organize chats into folders
- Dark mode optimized
- Face ID / Touch ID lock
- Works in English, Turkish, French, German, Spanish, Italian, Portuguese, Russian, Japanese, Korean, Chinese, Hindi, Arabic, Thai, and Ukrainian

**BUILT FOR PRIVACY**
- No analytics or tracking SDKs
- No ads
- Authentication via secure cookies
- Sign in with Apple supported
- Data stored on secure infrastructure in compliance with Turkish law

**SUBSCRIPTIONS**
- Starter, Pro, and Power plans available as monthly or yearly subscriptions
- Payment is charged to your Apple ID account
- Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period
- Manage or cancel anytime in Settings > Apple ID > Subscriptions

Privacy Policy: https://ai.gravitilabs.com/tabai/privacy
Terms of Service: https://ai.gravitilabs.com/tabai/terms

### Promotional Text (170 chars max, can be updated without review)
One app for ChatGPT, Claude, Gemini, DeepSeek, Grok and 40+ AI models. Free tier with 8 models, no credit card needed.

### Keywords (100 chars max, comma-separated)
Don't repeat words already in Name + Subtitle (AI, Chat, Assistant, GPT, Claude, Gemini are indexed from there).

**Keywords:**
chatbot,DeepSeek,Grok,LLM,Llama,Qwen,Mistral,ask,writer,copilot,bot,multi model,smart,answer,free

### What's New (Version 1.0)
Welcome to TABAI! Access 44 top AI models across Free, Starter, Pro, and Power tiers. Features include voice input, folder organization, Face ID lock, and 15 languages.

---

## 2. URLs for App Store Connect

| Field | URL |
|-------|-----|
| Privacy Policy URL | https://ai.gravitilabs.com/tabai/privacy |
| Support URL | https://ai.gravitilabs.com/tabai/support |
| Marketing URL | https://ai.gravitilabs.com |

---

## 3. Privacy Nutrition Labels

### Data Linked to You

| Data Type | Purpose | Linked to Identity |
|-----------|---------|-------------------|
| Email Address | App Functionality (account creation, sign-in) | Yes |
| Name (display name) | App Functionality (Apple Sign In) | Yes |

### Data Not Linked to You

| Data Type | Purpose |
|-----------|---------|
| Purchases | App Functionality (subscription verification) |

### Data Not Collected

The following data types are NOT collected:
- Location
- Contacts
- Photos or Videos
- Health & Fitness
- Financial Info (payments handled by Apple)
- Sensitive Info
- Browsing History
- Search History
- Diagnostics
- Usage Data (no analytics SDK)
- Identifiers (no device ID, IDFA, or fingerprinting)
- Other Data

### Detailed Privacy Answers for App Store Connect

**Do you or your third-party partners collect data from this app?**
Yes — email address and optional display name for account functionality only.

**Is the data used for tracking?**
No.

**Does your app use the App Tracking Transparency framework?**
No — not needed. No tracking occurs.

**Do you or your third-party partners use data for third-party advertising?**
No.

**Do you or your third-party partners use data for developer's advertising or marketing?**
No.

**Do you or your third-party partners use data for analytics?**
No.

**Do you or your third-party partners use data for product personalization?**
No — model selection is user-controlled, not algorithmic.

**Is the data linked to the user's identity?**
Email and display name: Yes (required for account).
Purchase history: No (handled by Apple, synced anonymously for entitlement).

---

## 4. App Review Compliance Checklist

### Guideline 1.2 — User-Generated Content
- [x] Chat content is private to each user (not shared publicly)
- [x] No user-to-user communication
- [x] No public feeds or profiles
- [x] AI responses are generated by third-party models via OpenRouter
- **Result**: UGC rules do NOT apply (private AI assistant, not social platform)

### Guideline 2.1 — App Completeness
- [x] App is fully functional at submission
- [x] All subscription tiers work end-to-end
- [x] Free tier provides genuine value (8 models, unlimited chats)
- [x] Demo account not needed (free sign-up available)

### Guideline 3.1.1 — In-App Purchase
- [x] All premium features gated behind IAP (not external payment)
- [x] Subscription terms clearly disclosed before purchase
- [x] Auto-renewal terms stated in paywall and description
- [x] Restore Purchases button available in paywall and settings
- [x] Manage Subscription link accessible

### Guideline 3.1.2 — Subscriptions
- [x] Free tier provides standalone value
- [x] Clear differentiation between tiers
- [x] No bait-and-switch (free users get real models)
- [x] Pricing displayed before purchase
- [x] Subscription terms in App Store description

### Guideline 5.1 — Privacy
- [x] Privacy policy URL set and accessible
- [x] Privacy policy covers all collected data types
- [x] Data collection is minimal (email + optional display name)
- [x] No third-party analytics or tracking
- [x] No IDFA / ATT usage
- [x] Sign in with Apple offered alongside other auth methods
- [ ] **PrivacyInfo.xcprivacy manifest required** — see action item below

### Guideline 5.1.1 — Data Collection and Storage
- [x] Auth tokens stored in Keychain (not UserDefaults)
- [x] Passwords never stored locally
- [x] Biometric data not stored (per-request LAContext challenge)

### Guideline 5.1.2 — Data Use and Sharing
- [x] No data sold to third parties
- [x] No data shared with advertisers
- [x] Chat content sent to OpenRouter for inference only (not stored by them)

### Guideline 2.5.4 — Background Modes
- [x] No background modes declared (no background fetch, audio, location)

### Guideline 4.0 — Design
- [x] Native SwiftUI interface
- [x] No web-view wrapper (SafariServices used only for external links)
- [x] Supports Dynamic Type: No (custom font sizes, but consistent)
- [x] Dark mode fully supported
- [x] iPad layout supported (device family includes iPad)

---

## 5. Required Action Items Before Submission

### BLOCKER: Create PrivacyInfo.xcprivacy
Apple requires a privacy manifest for all apps. Create this file with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeEmailAddress</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeName</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypePurchaseHistory</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

### Content Rights
- [x] App does not contain third-party content requiring licensing
- [x] AI model names used descriptively (not as trademarks)

### Age Rating Questionnaire
- Unrestricted Web Access: **No** (SafariServices opens links, but app itself is not a browser)
- Gambling: **No**
- Contests: **No**
- Violence: **No**
- Sexual Content: **No**
- Profanity: **Infrequent** (AI responses may contain mild language)
- Drugs/Alcohol: **No**
- Horror/Fear: **No**
- Medical/Treatment: **No**
- **Suggested Rating**: 4+ or 12+ (depending on Apple's assessment of AI-generated content)

### Screenshots Needed
| Device | Size | Orientation |
|--------|------|-------------|
| iPhone 16 Pro Max | 6.7" | Portrait |
| iPhone 16 Pro | 6.3" | Portrait |
| iPhone SE | 4.7" | Portrait (optional) |
| iPad Pro 13" | 13" | Portrait or Landscape |

**Suggested Screenshot Sequence (6 screens)**:
1. Empty state — "Ask anything" hero with suggestion chips
2. Chat conversation — showing AI response with clean typography
3. Model picker — showing tier grouping (Free/Starter/Pro/Power)
4. Paywall — showing plan comparison and scrolling model marquee
5. Sidebar/drawer — showing chat history and folders
6. Settings — showing voice input, Face ID, theme options

---

## 6. App Store Connect Field Reference

| Field | Value |
|-------|-------|
| App Name | TABAI - AI Chat Assistant |
| Subtitle | GPT, Claude, Gemini & More |
| Bundle ID | com.tahsinbayraktar.tai |
| SKU | tai-ios-v1 |
| Primary Language | English (U.S.) |
| Category | Productivity |
| Secondary Category | Utilities |
| Content Rights | Does not contain third-party content |
| Age Rating | 4+ (or 12+ if Apple flags AI content) |
| Privacy Policy URL | https://ai.gravitilabs.com/tabai/privacy |
| Support URL | https://ai.gravitilabs.com/tabai/support |
| Marketing URL | https://ai.gravitilabs.com |
| Copyright | 2026 TABA TASARIM INSAAT A.S. |
| Contact: First Name | Tahsin |
| Contact: Last Name | Bayraktar |
| Contact: Email | support@tahsinbayraktar.com |
| Contact: Phone | (your phone number) |
| Demo Account | Not needed (free sign-up) |
</content>
</invoke>