# TAI Devlog

## 2026-02-19
- Milestone 0 complete.
- Verified fullscreen background on iPhone SE and iPhone 15 Pro Max simulators.
- Milestone 1 complete (chat shell, suggestions, composer, tabs).
- Milestone 2 complete (mock streaming + message actions).
- Milestone 3 complete (attachments UI scaffolding).
- Milestone 4 complete (voice session UI + transcript + mock TTS).
- Milestone 5 complete (history list search/pin/rename/delete).
- Milestone 6 complete (settings selectors + voice session entry).
- Milestone 7 complete (persistence scaffolding for chats/history).
- Milestone 8 complete (auth hardening + token validation).
- Milestone 9 complete (QA pass + UI refinement).
- Milestone 10 complete (beta readiness polish).
- I2 complete: OpenWebUI auth wired to /api/owui/api/v1/auths/signin and /api/owui/api/v1/auths/me; OpenAPI unavailable (500).
- I3 complete: models from /api/owui/api/v1/models with fallback to local catalog; OpenAPI unavailable (500).
- I4 complete: conversations from /api/owui/api/v1/chats/ with cache upsert; detail via /api/owui/api/v1/chats/{id}.
- I5/I6 complete: chat completions + SSE streaming wired to /api/owui/api/v1/chat/completions and /api/chat/stream with stop support.
- I7 complete: profile read attempts via /users/me, /auths/me, /user/me; settings fallback to local defaults when endpoint unavailable.
- I8 complete: added timeouts/offline handling and graceful fallback logs (no UI changes).
- Models live wiring: OpenAPI discovery + endpoint selection + fallback with logs. OpenAPI URL: none (discovery failed). Models endpoint: fallback local.
