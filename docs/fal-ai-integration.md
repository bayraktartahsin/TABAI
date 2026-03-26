# TABAI — fal.ai Image & Video Integration Plan

> **Date:** 2026-03-22
> **Status:** Planning
> **Goal:** Add premium image generation (FLUX) and video generation (Kling, Veo, Sora) via fal.ai to TABAI on iOS, Android, and web admin

---

## 1. What You Need to Do (Step-by-Step)

### Step 1: Create fal.ai Account & Get API Key
1. Go to https://fal.ai and sign up
2. Go to https://fal.ai/dashboard/keys
3. Click "Add Key", name it "TABAI-Production"
4. Copy the API key — you'll add it as a Cloudflare secret

### Step 2: Deposit to fal.ai
**Recommended starting deposit: $50**

Why $50 is enough to start:
- FLUX.1 Schnell (fast image): ~$0.003/image → ~16,000 images
- FLUX.2 Pro (quality image): ~$0.03/image → ~1,600 images
- Kling 2.5 video (5s clip): ~$1.12/video → ~44 videos
- Veo 3.1 (5s, 1080p): ~$1.00/video → ~50 videos

For testing and first 100 users, $50 covers months of usage. Scale up when you have paying users.

### Step 3: Add API Key to Cloudflare
```bash
cd backend
# Add FAL_AI_API_KEY to .env file
# Paste your fal.ai key when prompted
```

### Step 4: Run the Autopilot Prompts (Section 6 below)

---

## 2. Architecture Design

### Current Flow (Text Chat)
```
iOS/Android → /api/chat/stream → backend → OpenRouter → SSE stream back
```

### New Flow (Image/Video Generation)
```
iOS/Android → /api/generate/image → backend → fal.ai queue → poll → result URL
iOS/Android → /api/generate/video → backend → fal.ai queue → poll → result URL
```

### Why Queue-Based (Not Streaming)
- Images take 2-10 seconds (FLUX Schnell: ~2s, FLUX Pro: ~8s)
- Videos take 30-120 seconds (Kling: ~60s, Veo: ~90s)
- fal.ai uses async queue: submit → poll status → get result
- Client shows progress indicator while polling

### Backend Flow
```
1. Client POST /api/generate/image { prompt, model, size, style }
2. Worker validates auth, plan tier, rate limits, cost budget
3. Worker POST https://queue.fal.run/{model-id} with Authorization: Key {FAL_KEY}
4. fal.ai returns { request_id }
5. Worker stores generation job in D1 (generations table)
6. Client polls GET /api/generate/status/{request_id}
7. Worker polls https://queue.fal.run/{model-id}/requests/{request_id}/status
8. When complete: Worker gets result, stores URL, returns to client
9. Client displays image/video inline in chat
```

---

## 3. "TABAI" Composite Free Model Concept

### The Idea
Create a branded "TABAI" model that Free tier users get. Behind the scenes, it intelligently routes to the best available free model based on the query type:

```
User asks question → TABAI routes to:
  - Code question → Qwen 2.5 Coder 7B (best free coder)
  - Math/reasoning → Phi-3 Mini (best free reasoner)
  - Creative writing → Llama 3.1 8B (best free creative)
  - General chat → Gemma 2 9B (best free all-rounder)
  - Turkish language → Qwen 2.5 7B (best free multilingual)
  - Quick answer → Llama 3.2 3B (fastest free)
```

### Implementation
- New endpoint logic in `lib.ts`: `routeTabaiModel(messages) → actualModelId`
- Simple keyword/heuristic classifier (no AI needed for routing)
- Show "TABAI" as the model name to the user
- Show "Powered by [actual model]" in small text below the answer
- This makes the Free tier feel premium — users think they're using "your" AI

### Premium Image/Video Naming
- Don't expose "FLUX" or "Kling" directly to casual users
- Show: "TABAI Image" (backed by FLUX) and "TABAI Video" (backed by Kling/Veo)
- Power users see the actual model name in model picker
- This builds brand value

---

## 4. fal.ai Model Selection & Tier Mapping

### Image Models

| Display Name | fal.ai Model ID | Tier | Cost/Image | Speed |
|---|---|---|---|---|
| TABAI Image Fast | fal-ai/flux/schnell | Starter | ~$0.003 | ~2s |
| TABAI Image | fal-ai/flux/dev | Pro | ~$0.025 | ~5s |
| TABAI Image Pro | fal-ai/flux-2-pro | Pro | ~$0.03 | ~8s |
| TABAI Image Ultra | fal-ai/flux-2-pro (max quality) | Power | ~$0.07 | ~12s |
| FLUX.1 with LoRA | fal-ai/flux-lora | Power | ~$0.035 | ~6s |

### Video Models

| Display Name | fal.ai Model ID | Tier | Cost/5s Video | Speed |
|---|---|---|---|---|
| TABAI Video | fal-ai/kling-video/v2.5/master/text-to-video | Pro | ~$1.12 | ~60s |
| TABAI Video Pro | fal-ai/veo3 (or veo3.1) | Power | ~$1.00 | ~90s |
| TABAI Video Ultra | fal-ai/sora-2-pro | Power | ~$2.50 | ~120s |

### Image-to-Video (animate a photo)

| Display Name | fal.ai Model ID | Tier | Cost |
|---|---|---|---|
| Animate Photo | fal-ai/kling-video/v2.5/master/image-to-video | Pro | ~$1.12 |
| Animate Photo Pro | fal-ai/veo3.1 (image-to-video) | Power | ~$1.00 |

---

## 5. Cost Safety for fal.ai

### Daily Limits Per Tier (Image/Video Separate from Text)

| Tier | Images/Day | Videos/Day | Max Daily fal.ai Spend |
|---|---|---|---|
| Free | 0 | 0 | $0 (no image/video) |
| Starter | 20 images | 0 videos | ~$0.06 |
| Pro | 50 images + 5 videos | 5 videos | ~$7.10 |
| Power | 200 images + 20 videos | 20 videos | ~$36.00 |

### Safety Guards (Same Pattern as OpenRouter)
- Per-user daily generation count limit
- Per-user daily fal.ai cost cap
- Global daily fal.ai spend circuit breaker (e.g., $200/day max across all users)
- Admin kill switch for image/video generation
- Queue size limit (max 3 concurrent generations per user)

---

## 6. Autopilot Prompts for Claude CLI

Run these in order. Each is one terminal session.

### Prompt 1: Database Migration + Backend Endpoints

```
M-FAL-1 — Add fal.ai integration to backend backend.

Read docs/milestones.md and docs/fal-ai-integration.md first.

STEP 1: Create D1 migration (next number after existing migrations in backend/migrations/):
CREATE TABLE generations (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  chat_id TEXT,
  fal_request_id TEXT NOT NULL,
  provider TEXT NOT NULL DEFAULT 'fal',
  model_id TEXT NOT NULL,
  model_display_name TEXT,
  generation_type TEXT NOT NULL CHECK(generation_type IN ('image','video','image_to_video')),
  status TEXT NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','processing','completed','failed','cancelled')),
  prompt TEXT NOT NULL,
  negative_prompt TEXT,
  parameters TEXT,
  result_url TEXT,
  result_metadata TEXT,
  estimated_cost_units INTEGER DEFAULT 0,
  actual_cost_units INTEGER,
  error_message TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  completed_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (chat_id) REFERENCES chats(id)
);
CREATE INDEX idx_generations_user ON generations(user_id, created_at);
CREATE INDEX idx_generations_status ON generations(status);
CREATE INDEX idx_generations_fal ON generations(fal_request_id);

STEP 2: Add to backend/src/lib.ts:
- submitFalGeneration(env, userId, chatId, model, prompt, params) — POST to queue.fal.run
- checkFalStatus(env, falRequestId, modelId) — GET status from fal.ai
- getFalResult(env, falRequestId, modelId) — GET completed result
- estimateFalCost(modelId, generationType) — return cost units
- checkFalBudget(env, db, userId, planTier, generationType) — daily limit check
- globalFalSpendCheck(env, db) — circuit breaker

fal.ai API pattern:
- Submit: POST https://queue.fal.run/{model-id} with headers Authorization: Key {FAL_AI_API_KEY}, Content-Type: application/json
- Status: GET https://queue.fal.run/{model-id}/requests/{request_id}/status
- Result: GET https://queue.fal.run/{model-id}/requests/{request_id}

STEP 3: Add endpoints to backend/src/endpoints/tai.ts:
- POST /api/generate/image — submit image generation
- POST /api/generate/video — submit video generation
- GET /api/generate/status/:id — poll generation status
- GET /api/generate/:id — get completed result
- GET /api/generate/history — user's generation history
- DELETE /api/generate/:id — cancel queued generation

All endpoints must: require auth, check plan tier, enforce rate limits, check fal budget, log safety events.

STEP 4: Register routes in index.ts following existing pattern.

STEP 5: Add FAL_AI_API_KEY to wrangler.jsonc vars section (as empty string placeholder, real key is a secret).

Do NOT touch iOS files. Backend only. Test by running npx wrangler dev and checking /docs for the new endpoints.
```

### Prompt 2: iOS Image Generation UI

```
M-FAL-2 — Add image generation UI to iOS app.

Read docs/milestones.md and docs/fal-ai-integration.md first.

IMPORTANT: The iOS project is at ios/TABAI/TABAI/. Follow existing code patterns exactly.

STEP 1: Create Services/FalAI/ directory with:
- FalAIServiceProtocol.swift — protocol with submitImage, submitVideo, checkStatus, getResult
- FalAIService.swift — real implementation calling /api/generate/* endpoints via existing OpenWebUIClient
- FalAIModels.swift — data models: GenerationRequest, GenerationStatus, GenerationResult, FalModel

STEP 2: Add fal.ai service to AppEnvironment.swift DI container.

STEP 3: Create Features/Generate/ directory with:

ImageGeneratorView.swift — Premium image generation screen:
- Clean white/dark background (match existing Perplexity-style)
- Large prompt input field at top (multi-line, placeholder "Describe what you want to create...")
- Style selector: Photo, Art, Illustration, 3D, Anime (horizontal scroll chips)
- Size selector: Square (1:1), Portrait (3:4), Landscape (4:3), Wide (16:9)
- Model selector showing TABAI Image / TABAI Image Pro / TABAI Image Ultra based on plan
- "Generate" button (accent color, full width)
- Generation history grid below (2-column, lazy load)

ImageGeneratorViewModel.swift — handles submit, polling, history

GenerationResultView.swift — Full-screen image viewer:
- Pinch to zoom
- Share button (UIActivityViewController)
- Save to Photos button
- "Use in Chat" button (attaches to current conversation)
- Regenerate button
- Shows prompt, model used, generation time

GenerationProgressView.swift — Loading state:
- Animated gradient shimmer (like a photo developing)
- Progress text: "Creating your image..." → "Almost ready..."
- Cancel button
- Estimated time remaining

STEP 4: Create Features/Generate/Video/:

VideoGeneratorView.swift — Video generation screen:
- Same clean layout as image
- Prompt input
- Duration selector: 3s, 5s, 10s
- Resolution: 720p, 1080p
- Model selector: TABAI Video / Video Pro / Video Ultra
- Option: Text-to-Video OR Image-to-Video (with photo picker)
- "Generate Video" button

VideoResultView.swift — Video player:
- AVPlayer inline with controls
- Share, Save, Use in Chat buttons
- Loop toggle

STEP 5: Add "Create" tab or button to NavigationShellView:
- Add a sparkle/wand icon button in the composer area or as a new mode
- When tapped, shows a bottom sheet with two options: "Generate Image" and "Generate Video"
- Each opens the respective view as a sheet

STEP 6: Add generation results inline in ChatView:
- When a generation completes, insert it as a special message type in the chat
- Image results: show thumbnail in chat, tap to open GenerationResultView
- Video results: show thumbnail with play icon, tap to open VideoResultView

Use existing DS.swift design tokens. Match the Perplexity-clean aesthetic. No glass cards — use flat clean cards with subtle shadows.
```

### Prompt 3: TABAI Composite Model (Smart Router)

```
M-FAL-3 — Implement TABAI composite model with smart routing.

Read docs/milestones.md and docs/fal-ai-integration.md first.

STEP 1: In backend/src/lib.ts, add routeTabaiModel function:

function routeTabaiModel(messages: Message[]): string {
  // Extract last user message text
  // Apply simple heuristic classification:
  // - Contains code keywords (function, class, import, error, bug, code) → "qwen/qwen-2.5-coder-7b-instruct"
  // - Contains math keywords (calculate, equation, proof, math, solve) → "microsoft/phi-3-mini-128k-instruct"
  // - Contains creative keywords (write, story, poem, creative, imagine) → "meta-llama/llama-3.1-8b-instruct"
  // - Contains Turkish text (detect via character patterns) → "qwen/qwen-2.5-7b-instruct"
  // - Message is short (<20 chars, likely quick question) → "meta-llama/llama-3.2-3b-instruct"
  // - Default → "google/gemma-2-9b-it"
  // Return the OpenRouter model ID
}

STEP 2: In ChatStreamRoute handler, add TABAI model logic:
- If selected model is "tabai" or "tabai-free", run routeTabaiModel to get actual model
- Pass actual model to OpenRouter
- In the SSE response, include a metadata event with the actual model used
- Store actual model in the message record for analytics

STEP 3: Register "tabai" as a virtual model in the models table:
- Add migration: INSERT INTO models with id='tabai', name='TABAI', provider='tabai', is_enabled=1, plan_tier='free'
- Set capabilities: streaming=true, vision=false, reasoning=false

STEP 4: In iOS ModelCatalog.swift:
- Add TABAI as the first model in the Free tier list
- Show it with a special animated gradient icon (brand identity)
- Subtitle: "Smart AI — automatically picks the best model for your question"
- After response, show small text below answer: "Powered by [actual model name]"

STEP 5: In ChatBubbleView.swift (or AnswerCardView if renamed):
- Add "Powered by" label that shows which actual model answered
- Only show this for TABAI model responses
- Style: small, muted text, 11pt, below the answer content
```

### Prompt 4: Android Image/Video Generation (After iOS Ships)

```
M6-FAL — Add fal.ai image and video generation to Android app.

Read docs/milestones.md and docs/fal-ai-integration.md first.

This is for the Android (Kotlin + Jetpack Compose) app. The backend endpoints already exist from M-FAL-1.
Replicate the exact same UX as iOS (M-FAL-2) but in Compose.

STEP 1: Create data layer:
- GenerationRepository.kt — calls /api/generate/* endpoints
- GenerationModels.kt — data classes matching iOS FalAIModels
- GenerationStatus sealed class (Queued, Processing, Completed, Failed)

STEP 2: Create UI:
- ImageGeneratorScreen.kt — matching iOS ImageGeneratorView exactly
- VideoGeneratorScreen.kt — matching iOS VideoGeneratorView exactly
- GenerationResultScreen.kt — full-screen viewer with share/save
- GenerationProgressIndicator.kt — animated shimmer loading

STEP 3: Navigation:
- Add "Create" entry point matching iOS placement
- Bottom sheet with Image/Video options

STEP 4: Inline chat results:
- ChatBubble composable shows generation thumbnails
- Tap opens full result viewer

Use Material 3 Design tokens matching the iOS DS.swift values.
```

---

## 7. Updated Milestone Map

Add these to docs/milestones.md:

```
### M-FAL — fal.ai Image & Video Integration

#### M-FAL-1: Backend + Database (Est: 1 session)
- [ ] D1 migration for generations table
- [ ] fal.ai submit/status/result functions in lib.ts
- [ ] Cost estimation and budget checking
- [ ] 6 new API endpoints
- [ ] Route registration
- [ ] FAL_AI_API_KEY secret configuration

#### M-FAL-2: iOS Image & Video UI (Est: 2-3 sessions)
- [ ] FalAI service layer
- [ ] ImageGeneratorView with style/size/model selectors
- [ ] VideoGeneratorView with duration/resolution
- [ ] GenerationResultView (image viewer with share/save)
- [ ] VideoResultView (video player)
- [ ] GenerationProgressView (animated loading)
- [ ] Create button integration in composer/navigation
- [ ] Inline generation results in chat

#### M-FAL-3: TABAI Composite Model (Est: 1 session)
- [ ] Smart routing function (keyword-based classifier)
- [ ] TABAI virtual model registration
- [ ] iOS model picker integration
- [ ] "Powered by" label in answer cards

#### M-FAL-4: Android Image & Video (Est: 2 sessions, after M6 base)
- [ ] Android data layer
- [ ] Android Compose UI (match iOS)
- [ ] Navigation integration
- [ ] Inline chat results
```

---

## 8. Priority Order

1. **Finish M5A-11** (App Store screenshots) — you're almost done
2. **M5A-12** (Typography & motion polish)
3. **M-FAL-1** (Backend — no UI changes, pure backend)
4. **M-FAL-3** (TABAI composite model — quick win, improves Free tier immediately)
5. **M-FAL-2** (iOS image/video UI — the big visual feature)
6. **M5B** (iOS hardening)
7. **Submit iOS to App Store**
8. **M6** (Android base port)
9. **M-FAL-4** (Android image/video)
10. **Submit Android to Play Store**

---

## 9. Deposit Scaling Guide

| Stage | Deposit | Covers |
|---|---|---|
| Development & testing | $50 | Months of dev testing |
| TestFlight beta (50 users) | +$100 | 1-2 months beta |
| App Store launch (500 users) | +$500 | First month at scale |
| Growth (5,000 users) | +$2,000/mo | Depends on Pro/Power ratio |
| Scale (50,000 users) | Review unit economics | Should be profitable from subscriptions |

Your subscription pricing covers fal.ai costs with healthy margins:
- Starter ($6.99/mo): 20 images/day = ~$1.80/mo cost → $5.19 margin
- Pro ($29.99/mo): 50 images + 5 videos/day = ~$170/mo cost at MAX usage (most users use 10-20%) → needs monitoring
- Power ($79.99/mo): Heavy users — healthy margins, adjust limits if needed
