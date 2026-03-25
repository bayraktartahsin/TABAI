# ChatGPT Parity Plan and Checklist

## Milestones

### Milestone 1 — Audit + Streaming Backbone
Files:
- `/docs/ARCHITECTURE.md`
- `/docs/CHATGPT_PARITY.md`
- `/app/api/chat/stream/route.ts`
- `/lib/owui/client.ts`
- `/components/chat/ChatScreen.tsx`

Risks:
- Upstream provider stream format variance.
- Incomplete cookie-session forwarding across domains.

Definition of done:
- Token-by-token UI updates.
- Stop button aborts stream.
- Regenerate triggers a new streamed assistant response.

### Milestone 2 — Chat UI Parity (suggestions + actions + polish)
Files:
- `/components/chat/ChatScreen.tsx`
- `/components/chat/FileDropZone.tsx`
- new chat action components

Risks:
- Scope creep in UX without backend support.

Definition of done:
- Empty-state suggested prompts.
- Follow-up suggestions after responses.
- Message actions: copy/retry/edit/feedback.
- Mic speech-to-text with fallback message.
- Vision gating for image attachments.

### Milestone 3 — Provider + Model Registry (Admin)
Files:
- new `/app/admin/*` data-backed pages
- new `/app/api/admin/providers/*` and `/app/api/openrouter/models`
- DB schema/migrations

Risks:
- Requires secure server persistence, encryption key management.

Definition of done:
- Admin can switch runtime provider and run health checks.
- Runtime model loading is sourced from tai-edge + OpenRouter.
- Runtime streaming path is sourced from tai-edge + OpenRouter.
- Next step: add persistent DB-backed provider/model CRUD + encrypted secrets.

### Milestone 4 — Auth/RBAC hardening + user isolation
Files:
- auth routes/middleware
- admin user management routes/pages
- DB query layer for chats/messages

Risks:
- Migration from localStorage chat history to server data.

Definition of done:
- Public signup removed.
- Admin-only user creation.
- `/admin/**` protected by role.
- User can only access own chats/messages at DB query layer.

### Milestone 5 — Attachments, mic, tests, QA
Files:
- upload handlers and validators
- speech input client integration
- tests + QA docs

Risks:
- Browser compatibility and resource limits.

Definition of done:
- image/file upload flow with capability checks.
- speech-to-text fallback behavior.
- integration + RBAC tests passing.

---

## Acceptance Checklist
- [x] Assistant response streams incrementally, not one blob.
- [x] Stop button cancels generation.
- [x] Regenerate reruns last assistant turn.
- [ ] Suggestions on empty chat and follow-up suggestions after response.
- [x] Suggestions on empty chat and follow-up suggestions after response.
- [x] Mic speech-to-text input (Web Speech API with fallback).
- [x] Image upload + vision capability gating.
- [~] Admin provider/model management (runtime switch + health checks done; DB/encrypted CRUD pending).
- [ ] Admin-created users only (no signup).
- [~] User chat isolation improved (browser storage now namespaced by `user_id`; server-side DB isolation still pending).
- [ ] Responsive + accessibility + overflow QA complete.
