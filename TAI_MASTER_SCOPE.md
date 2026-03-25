# TAI — Master Product Scope & Milestone Tracker

> **Owner:** Volkan Bayraktar
> **Product:** TAI Multi-AI Assistant (Web + iOS + Android)
> **Domain:** ai.gravitilabs.com
> **Last Updated:** 2026-03-19
> **Status:** Active Development — iOS M5A-2 next

---

## Architecture Summary

```
Browser/iOS/Android → ai.gravitilabs.com
  → Static assets served by Worker (Next.js 14 export)
  → /api/* → tai-edge (Cloudflare Worker + Hono + D1)
  → OpenRouter (300+ models, streaming SSE)
```

**Backend:** 42 API endpoints, cookie-based auth, D1 SQLite, OpenRouter integration
**Web:** Next.js 14 static export, React 18, TypeScript
**iOS:** SwiftUI 17+, StoreKit 2, 67 Swift files
**Android:** Not started (planned Kotlin/Compose)

---

## Completed Milestones

### ✅ M1 — Core SaaS Foundation
Auth, chat streaming, model routing, pricing pages, legal pages, web app E2E.

### ✅ M2 — Monetization Wiring
StoreKit plans (Starter/Pro/Power), restore logic, entitlements, subscription UI.

### ✅ M3 — Cost Safety & Abuse Protection
Per-user usage tracking, daily cost caps (per plan), RPM limiter, token limits, concurrency leases, expensive model allowlist, admin kill switch, safety audit logs, global spend circuit breaker.

### ✅ M5C — Legal & Compliance Fix
- [x] Replaced all 8x `SUPPORT_EMAIL_PLACEHOLDER` with `support@tahsinbayraktar.com`
- [x] Replaced `SUPPORT_RESPONSE_TIME_PLACEHOLDER` with `within 3 business days`
- [x] Added company address: Şehit Şakir Elkovan cad. No:3 Ataşehir Istanbul Türkiye
- [x] Added governing law: Türkiye (to Terms and Privacy pages)
- [x] Fixed production hosting: enabled Worker static assets to serve frontend
- [x] All 5 legal URLs verified 200 OK on production
- [x] iOS LegalLinks.swift URLs updated to ai.tahsinbayraktar.com

### ✅ M5A-1 — Service Wiring (verified complete)
- [x] HistoryView wired to real ChatService via `.configure()` in `.task`
- [x] SettingsView wired to real SettingsService via `.configure()` in `.task`
- [x] Settings persist to backend via PATCH /api/settings
- [x] `featureFlags.useOpenWebUI = true` hardcoded in AppEnvironment

---

## Active & Future Milestones

### 🟡 M5A — iOS Perplexity-Class UX (CURRENT)

**Goal:** Complete Perplexity-style redesign of the entire iOS app — chat, drawer, settings, usage, paywall, and model experience.

#### M5A-2: Perplexity-Style Chat & Home Redesign
- [ ] **Home/Empty State**: Clean search-first layout
  - Large centered "Ask anything" prompt
  - Suggestion chips below (trending/contextual)
  - Model selector as subtle pill at top
  - Clean white/dark surface (remove heavy gradient background)
- [ ] **Chat View → Answer Cards**:
  - Answer cards with clean typography (replace chat bubbles)
  - Follow-up suggestions after each answer
  - Smooth word-by-word streaming appearance
  - Copy/share/regenerate buttons per answer
  - Markdown rendering with proper code blocks
- [ ] **Composer**: Perplexity-style bottom bar
  - Minimal pill shape with mic + attach + send
  - Model selector integrated or above composer
  - Focus mode: expand on tap
  - Height auto-grow with max cap

#### M5A-3: Left Drawer & Navigation (Perplexity-Style)
- [ ] **Drawer redesign**: Clean, minimal like Perplexity sidebar
  - "New Thread" button at top (prominent)
  - Conversation list grouped by Today / Yesterday / Previous 7 Days / Older
  - Each item: title only (no preview text), subtle model badge
  - Swipe actions: rename, delete, pin
  - Folder sections (collapsible)
- [ ] **Drawer bottom section**:
  - User avatar + email (compact)
  - Quick links: Settings, Usage, Upgrade
  - App version subtle at bottom
- [ ] New Chat clears state properly
- [ ] Active conversation highlighting
- [ ] Smooth open/close gesture animations
- [ ] Empty state onboarding message

#### M5A-4: Settings & Profile (Perplexity-Style)
- [ ] **Settings main page**: Clean grouped sections like Perplexity
  - Account section: Profile, Subscription, Usage
  - Preferences section: Appearance, Language, Notifications, Permissions, Haptics
  - About section: Legal links, App version, Sign Out
- [ ] **Profile page**: Clean card with avatar placeholder, email, plan badge
- [ ] **All sub-pages**: Consistent Perplexity-clean styling (remove glass cards, use flat clean cards)

#### M5A-5: Usage Display (Claude-Style Dynamic Tokens)
- [ ] **Usage page redesign** — show real-time token consumption like Claude:
  - Visual progress bar: tokens used / daily limit
  - Visual progress bar: cost units used / daily limit
  - Numeric display: "12,450 / 25,000 tokens used today"
  - Reset countdown timer: "Resets in 14h 23m"
  - Color coding: green (<50%), yellow (50-80%), red (>80%)
- [ ] **Per-model breakdown**: Show which models consumed what
- [ ] **Upgrade prompt**: When approaching limit, show contextual upgrade CTA
- [ ] **Backend**: Add `GET /api/usage` endpoint returning:
  - `tokensUsed`, `tokenLimit`, `costUnitsUsed`, `costUnitLimit`
  - `resetAt` (timestamp), `concurrentStreams`, `streamLimit`
  - Per-model usage breakdown (last 24h)

#### M5A-6: Rebrand TAI → TABA
- [ ] Rename app display name to "TABA" in all Localizable.strings (en, tr, base)
- [ ] Update chat placeholder: "Message TABA" / "TABA'ya mesaj yaz"
- [ ] Update bundle identifier: com.tahsinbayraktar.taba
- [ ] Update web: layout.tsx title, manifest.webmanifest, legal pages ("TABA AI Assistant")
- [ ] Update all 5 legal pages: TAI AI Assistant → TABA AI Assistant
- [ ] Update LegalDocumentPage.tsx header eyebrow
- [ ] Update ChatView header text, AnimatedBrandLogo references
- [ ] Animated logo with flowing gradient colors (elite look)
- [ ] Logo in drawer header
- [ ] Rebuild web frontend, deploy

#### M5A-7: Auth — Apple & Google Sign-In
- [ ] Add Sign in with Apple capability to Xcode project
- [ ] Implement Apple Sign-In flow (ASAuthorizationController)
- [ ] Backend: Add `POST /api/auth/apple` endpoint (verify identity token)
- [ ] Implement Google Sign-In (GoogleSignIn SDK or web OAuth)
- [ ] Backend: Add `POST /api/auth/google` endpoint (verify ID token)
- [ ] Redesign SignInView Perplexity-style (clean, centered, social buttons prominent)
- [ ] Wire SignInViewModel to real Apple/Google providers

#### M5A-8: Projects in Drawer (Claude/ChatGPT-style)
- [ ] Rename "Folders" to "Projects" in UI
- [ ] Add project description field
- [ ] Add project color/icon picker
- [ ] Collapsible project sections in drawer
- [ ] Project context: show project name in chat header when active
- [ ] "All Chats" vs per-project filtering
- [ ] Backend: Add project description field to folders table (migration)

#### M5A-9: Model Curation & Tier Assignment
- [ ] Curate from 300+ → ~40-50 quality models (see Model Curation Plan)
- [ ] Backend: Set `is_enabled = 0` for uncurated models
- [ ] Ensure no "(free)" text in any model display names
- [ ] Tier badges in model picker: Free / Starter / Pro / Power
- [ ] Model picker redesign: grouped by category with tier indicators
- [ ] Search/filter within picker

#### M5A-10: Paywall Redesign (Animated Model Showcase)
- [ ] Perplexity-style paywall with animated model flow per tier
- [ ] Plan comparison: side-by-side feature grid
- [ ] Contextual upgrade: when user hits limit or tries locked model
- [ ] Yearly savings highlight with percentage badge

#### M5A-11: App Store Submission Package
- [ ] App Store screenshots (iPhone 14/15/16 sizes, 6.7" and 6.1") — sequence defined in APPSTORE_SUBMISSION.md
- [x] App Store metadata: description, keywords, category, subtitle
- [x] Privacy nutrition labels
- [x] App Store Connect: all required fields documented
- [x] App Review guidelines compliance check
- [x] Privacy policy URL, support URL, marketing URL — verified live
- [x] PrivacyInfo.xcprivacy manifest created

#### M5A-12: Typography, Spacing & Motion
- [ ] Consistent font sizing across all views
- [ ] Proper line heights for readability
- [ ] Padding/margin consistency audit
- [ ] Safe area handling on all iPhone sizes
- [ ] Subtle entrance animations for messages
- [ ] Smooth keyboard handling (no jumps)
- [ ] Loading skeletons for all async content
- [ ] Haptic feedback on key interactions

---

## Model Curation Plan

Curate from 300+ OpenRouter models down to ~40-50 high-quality models across 4 tiers.

### Free Tier (available to all users on signup)
> Daily limit: 25K tokens, 3K cost units

| Model | Provider | Why |
|-------|----------|-----|
| Llama 3.1 8B Instruct | Meta | Best free general-purpose |
| Llama 3.2 3B Instruct | Meta | Ultra-fast, mobile-friendly |
| Gemma 2 9B | Google | Strong free alternative |
| Qwen 2.5 7B Instruct | Alibaba | Excellent multilingual free |
| Mistral 7B Instruct | Mistral | Reliable European free model |
| Phi-3 Mini | Microsoft | Compact, good reasoning |

### Starter Tier ($4.99/mo) — Fast & Everyday + Vision
> Daily limit: 120K tokens, 20K cost units

| Model | Provider | Category |
|-------|----------|----------|
| GPT-4o Mini | OpenAI | Fast everyday |
| Claude 3.5 Haiku | Anthropic | Fast everyday |
| Gemini 2.0 Flash | Google | Fast everyday |
| Llama 3.1 70B Instruct | Meta | Strong open-source |
| Mistral Small | Mistral | European fast |
| Qwen 2.5 72B Instruct | Alibaba | Multilingual powerhouse |
| DeepSeek V3 | DeepSeek | Cost-efficient |
| GPT-4o Mini (vision) | OpenAI | Vision |
| Gemini 2.0 Flash (vision) | Google | Vision |
| Llama 3.2 11B Vision | Meta | Open-source vision |

### Pro Tier ($14.99/mo) — Premium Reasoning + Creative
> Daily limit: 450K tokens, 90K cost units

| Model | Provider | Category |
|-------|----------|----------|
| GPT-4o | OpenAI | Premium creative |
| Claude 3.5 Sonnet | Anthropic | Premium creative |
| Gemini 1.5 Pro | Google | Premium creative |
| DeepSeek R1 | DeepSeek | Reasoning |
| Llama 3.1 405B Instruct | Meta | Largest open-source |
| Mistral Large | Mistral | European premium |
| Qwen QwQ 32B | Alibaba | Reasoning |
| DALL-E 3 | OpenAI | Image generation |
| Flux Pro | Black Forest | Image generation |
| Stable Diffusion XL | Stability | Image generation |

### Power Tier ($29.99/mo) — Everything Unlocked
> Daily limit: 1.5M tokens, 300K cost units

| Model | Provider | Category |
|-------|----------|----------|
| Claude 3 Opus | Anthropic | Ultra creative |
| GPT-4 Turbo | OpenAI | Ultra creative |
| O1 | OpenAI | Ultra reasoning |
| O3 | OpenAI | Ultra reasoning |
| O1 Mini | OpenAI | Fast reasoning |
| Gemini 1.5 Pro (max context) | Google | Ultra context |
| All Pro tier models | — | Included |
| All Starter tier models | — | Included |
| All Free tier models | — | Included |

### Hidden/Disabled (not shown to users)
- Embedding models, moderation models, TTS, transcription, rerankers
- Duplicate/aliased versions of same model
- Unverified or unstable models
- Models with no clear use case or poor quality

---

### 🟢 M-FAL — fal.ai Image & Video Integration

**Goal:** Add premium image generation (FLUX) and video generation (Kling, Veo, Sora) via fal.ai + TABAI composite smart model.

**Reference:** See `FAL_AI_INTEGRATION_PLAN.md` for full details, autopilot prompts, and pricing.

#### ✅ M-FAL-1: Backend + Database
- [x] D1 migration 0012 for generations table (columns, indexes, foreign keys)
- [x] fal.ai submit/status/result functions in lib.ts
- [x] Cost estimation and budget checking (per-tier daily limits, global circuit breaker)
- [x] 6 new API endpoints (generate/image, generate/video, generate/status/:id, generate/:id, generate/history, DELETE generate/:id)
- [x] Route registration in index.ts
- [x] FAL_AI_API_KEY secret configured via wrangler

#### ✅ M-FAL-2: iOS Image & Video UI
- [x] FalAI service layer (FalAIServiceProtocol + FalAIService + FalAIModels)
- [x] ImageGeneratorView with style/size/model selectors
- [x] VideoGeneratorView with duration/resolution/mode (text-to-video + image-to-video)
- [x] GenerationResultCard (image viewer with share/save + full-screen pinch-to-zoom)
- [x] VideoResultCard (AVPlayer with loop toggle)
- [x] GenerationProgressView (animated shimmer loading)
- [x] Create button integration in ComposerToolsSheet
- [x] AppEnvironment DI wired

#### ✅ M-FAL-3: TABAI Composite Model (Smart Router)
- [x] Smart routing function in lib.ts (Turkish/code/math/creative/quick/default classifier)
- [x] TABAI virtual model registration in D1 (migration 0013)
- [x] Added to CURATED_MODELS map (appears in all users' model lists)
- [x] ChatStreamRoute intercepts TABAI model, routes to actual model, sends metadata SSE event
- [x] iOS: ChatBubbleView shows "Powered by [model]" label for TABAI responses
- [x] iOS: TABAIChatService handles metadata SSE event

#### ✅ M-FAL-4: Android Image & Video
- [x] Android data layer (GenerationDTOs, GenerationRepository, TABAIApi endpoints)
- [x] Android Compose UI (ImageGeneratorScreen, VideoGeneratorScreen matching iOS)
- [x] Navigation integration (AttachmentSheet with Generate Image/Video options, full-screen dialogs)
- [x] GenerationViewModel with polling state machine
- [x] "Powered by" label in ChatBubble for TABAI composite model
- [x] ChatViewModel handles metadata SSE event

---

### 🟠 M5B — iOS Release Hardening (after M5A)

**Goal:** App Store submission readiness.

- [ ] Real device testing (iPhone 14/15/16 sizes)
- [ ] Memory leak profiling (Instruments)
- [ ] Streaming cancel stress test (rapid send/cancel)
- [ ] Purchase restore edge cases
- [ ] Offline state UX (graceful degradation)
- [ ] Loading skeleton polish
- [ ] Crash log instrumentation (e.g. Firebase Crashlytics or Sentry)
- [ ] App Store screenshots & metadata
- [ ] Privacy nutrition labels
- [ ] App Review guidelines compliance check

---

### 🟣 M6 — Android Fast Port (after iOS ships)

**Goal:** Android app matching iOS feature parity.

**Strategy:** Reuse all backend APIs, replicate iOS design decisions.

- [ ] Kotlin + Jetpack Compose project setup
- [ ] Design system tokens (match iOS DS.swift)
- [ ] Auth flow (email sign-in, same cookie-based session)
- [ ] Chat interface with streaming
- [ ] Model picker with plan restrictions
- [ ] Conversation drawer/sidebar
- [ ] Google Play Billing (match StoreKit tiers)
- [ ] Settings + preferences
- [ ] Chat history
- [ ] Legal document links
- [ ] Deep link support

---

### 🔵 M7 — Payment & Revenue Scaling (Post-launch)

- [ ] Overage wallet credits ($20 packs)
- [ ] Global spend alert dashboard
- [ ] Model cost analytics
- [ ] Churn funnel analytics
- [ ] Pricing optimization experiments
- [ ] Web payment integration (Stripe)

---

### ⚫ M8+ — Future (DO NOT START)

- Voice assistant mode
- macOS native app
- VS Code extension
- Web search integration (Perplexity-style sources)
- Enterprise features (SSO, team management)
- Fine-tuned model infrastructure
- Proprietary model training

---

## Progress Dashboard

| Milestone | Progress | Blocking? | ETA |
|-----------|----------|-----------|-----|
| M1 Core SaaS | ██████████ 100% | — | ✅ Done |
| M2 Monetization | ██████████ 100% | — | ✅ Done |
| M3 Cost Safety | ██████████ 100% | — | ✅ Done |
| M5C Legal Fix | ██████████ 100% | — | ✅ Done |
| M5A-1 Service Wiring | ██████████ 100% | — | ✅ Done |
| M5A-2 Chat & Home UX | ██████████ 100% | — | ✅ Done |
| M5A-3 Drawer & Nav | ██████████ 100% | — | ✅ Done |
| M5A-4 Settings & Profile | ██████████ 100% | — | ✅ Done |
| M5A-5 Usage (Claude-style) | ██████████ 100% | — | ✅ Done |
| M5A-6 Rebrand TABAI | ██████████ 100% | — | ✅ Done |
| M5A-7 Apple/Google Auth | ██████████ 100% | — | ✅ Done |
| M5A-8 Projects in Drawer | ██████████ 100% | — | ✅ Done |
| M5A-9 Model Curation | ██████████ 100% | — | ✅ Done |
| M5A-10 Paywall Redesign | ██████████ 100% | — | ✅ Done |
| M5A-11 App Store Package | ████████░░ 85% | Screenshots remaining | 1 day |
| M5A-12 Typography & Motion | ░░░░░░░░░░ 0% | After M5A-11 | 1 day |
| M-FAL-1 Backend + DB | ░░░░░░░░░░ 0% | After M5A-12 | 1 session |
| M-FAL-3 TABAI Model | ░░░░░░░░░░ 0% | After M-FAL-1 | 1 session |
| M-FAL-2 iOS Image/Video | ░░░░░░░░░░ 0% | After M-FAL-3 | 2-3 sessions |
| M5B iOS Hardening | ░░░░░░░░░░ 0% | After M-FAL-2 | 2-3 days |
| M6 Android | ░░░░░░░░░░ 0% | After M5B | 10-14 days |
| M-FAL-4 Android Image/Video | ░░░░░░░░░░ 0% | After M6 | 2 sessions |
| M7 Revenue | ░░░░░░░░░░ 0% | Post-launch | TBD |

**Overall Product Readiness: ~45% toward market launch**

---

## File Reference Map

### iOS Key Files
```
ios/TABAI/TABAI/App/AppEnvironment.swift          — DI container, app state
ios/TABAI/TABAI/Features/Chat/ChatView.swift      — Main chat UI (REDESIGN: M5A-2)
ios/TABAI/TABAI/Features/Chat/Views/ComposerView.swift — Message input (REDESIGN: M5A-2)
ios/TABAI/TABAI/Features/Chat/Views/ChatBubbleView.swift — Message rendering (REPLACE: M5A-2)
ios/TABAI/TABAI/Features/Chat/ChatViewModel.swift — Chat logic + streaming
ios/TABAI/TABAI/Features/Navigation/NavigationShellView.swift — Drawer shell (REDESIGN: M5A-3)
ios/TABAI/TABAI/Features/Navigation/ConversationDrawerView.swift — Sidebar (REDESIGN: M5A-3)
ios/TABAI/TABAI/Features/History/HistoryView.swift — Chat history (wired to real service)
ios/TABAI/TABAI/Features/Settings/SettingsView.swift — Settings (REDESIGN: M5A-4)
ios/TABAI/TABAI/Features/Subscriptions/SubscriptionView.swift — Paywall (REDESIGN: M5A-7)
ios/TABAI/TABAI/Core/Config/LegalLinks.swift — Legal URLs (✅ fixed)
ios/TABAI/TABAI/Core/DesignSystem/DS.swift — Design tokens
ios/TABAI/TABAI/Services/ — Service protocols + OpenWebUI implementations
```

### Web Key Files
```
hf-taiapp/components/chat/ChatScreen.tsx — Chat interface
hf-taiapp/components/ui/AppShell.tsx — Main orchestrator
hf-taiapp/components/ui/Sidebar.tsx — Navigation sidebar
hf-taiapp/components/ui/LoginScreen.tsx — Auth UI
hf-taiapp/components/panels/PricingPage.tsx — Pricing
hf-taiapp/components/legal/LegalDocumentPage.tsx — Legal template
hf-taiapp/app/privacy/page.tsx — Privacy policy (✅ fixed)
hf-taiapp/app/terms/page.tsx — Terms (✅ fixed)
hf-taiapp/app/acceptable-use/page.tsx — AUP (✅ fixed)
hf-taiapp/app/subscription/page.tsx — Billing (✅ fixed)
hf-taiapp/app/support/page.tsx — Support (✅ fixed)
hf-taiapp/lib/design-system/tokens.ts — Theme tokens
hf-taiapp/lib/tai/client.ts — API client
```

### Backend Key Files
```
tai-edge/src/index.ts — Route registration, static assets, CORS
tai-edge/src/lib.ts — All business logic (4000+ lines)
tai-edge/src/endpoints/tai.ts — 42 endpoint handlers
tai-edge/src/types.ts — Zod schemas
tai-edge/wrangler.jsonc — Cloudflare config (now includes static assets)
tai-edge/migrations/ — D1 schema (8 migrations)
```
