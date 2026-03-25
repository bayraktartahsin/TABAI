# TAI Milestones

## Web Platform Rebuild Plan

Primary target: `/Users/bayraktar/Documents/New Apps/TAI/hf-taiapp`

### Milestone 0 — Repository Audit And Consolidation
- [x] Audit full repository
- [x] Identify active stacks and duplicated web apps
- [x] Create root architecture audit
- [ ] Mark `hf-taiapp` as the single production web app and treat `tai-premium-ui` as reference-only

### Milestone 1 — Production Backend Foundation
- [ ] Add Prisma schema and migrations
- [ ] Add first-party users, sessions, RBAC, and admin-only user creation
- [ ] Add encrypted provider/API key storage
- [ ] Add audit log and soft-delete archive models
- [ ] Add server utilities for auth, crypto, validation, and rate limiting

### Milestone 2 — AI Provider Layer
- [ ] Keep OpenRouter as the production provider and add optional providers only if required later
- [ ] Add model registry with per-model credential requirements
- [ ] Add per-user model access control
- [ ] Add provider health monitoring and usage tracking
- [ ] Route streaming chat completions through a unified adapter layer

### Milestone 3 — DB-Backed Chat System
- [ ] Move chats/messages from `localStorage` to database
- [ ] Add chat folders
- [ ] Add rename, soft delete, permanent admin purge
- [ ] Add message edit/retry/share/copy metadata
- [ ] Add paginated history loading optimized for large histories

### Milestone 4 — Premium Web UI System
- [ ] Add Tailwind CSS, `shadcn/ui`, and `lucide-react`
- [ ] Rebuild shell, sidebar, composer, message list, settings, and admin screens on the new design system
- [ ] Keep ChatGPT-style interactions: sticky composer, icon controls, model switcher, folders, streaming cursor
- [ ] Make mobile layout first-class

### Milestone 5 — Admin Platform
- [ ] User management: create, rename, reset password, freeze, enable, delete
- [ ] Provider management: add/edit/test credentials and endpoints
- [ ] Model management: display name, logo, required fields, access rules
- [ ] Analytics: chat volume, token usage, provider health, user activity
- [ ] Chat monitoring and audit visibility

### Milestone 6 — Security And Reliability
- [ ] Enforce RBAC on all protected routes
- [ ] Add rate limiting
- [ ] Add secure cookie sessions
- [ ] Add encrypted secrets rotation strategy
- [ ] Add export and notification preferences

### Milestone 7 — Testing And QA
- [ ] Auth tests
- [ ] Chat and streaming tests
- [ ] Admin and RBAC tests
- [ ] Provider adapter tests
- [ ] Build verification and regression pass

### Milestone 8 — Cross-Platform API Alignment
- [ ] Stabilize API contracts for iOS compatibility
- [ ] Document auth/chat/model/settings endpoints for native client use
- [ ] Keep app-facing APIs provider-agnostic while maintaining OpenRouter as default

## iOS Milestones

- [x] Milestone 0 — Reset & Scaffold
  - [x] Delete old iOS app code
  - [x] Create new SwiftUI iOS 17 project structure
  - [x] Setup DI container, localization scaffolding, theme system, keychain wrapper
  - [x] App runs: Splash -> Sign In
- [x] Milestone 1 — Sign In only (local demo)
  - [x] Validation, disabled state, error UI
  - [x] Keychain mock token persistence
  - [x] Auto-login if token exists
  - [x] Sign out
- [x] Milestone 2 — App Shell + Routing
  - [x] Tab bar: Chat / History / Profile
  - [x] Basic navigation and empty states
- [x] Milestone 3 — Chat UI + Composer + Keyboard
  - [x] Chat list, bubbles, markdown rendering
  - [x] Sticky composer, send button logic
  - [x] Suggested prompts for empty state
- [x] Milestone 4 — Mock streaming + message actions
  - [x] Token streaming
  - [x] Stop generating
  - [x] Regenerate last assistant response
  - [x] Copy message
  - [x] Edit user message + rerun local
- [x] Milestone 5 — History + Persistence
  - [x] Local conversation/message persistence
  - [x] History list search/rename/delete/pin
  - [x] Open conversation in chat
- [x] Milestone 6 — Attachments scaffolding
  - [x] Photo picker, camera, files picker
  - [x] Attachment chips + preview
  - [x] Save local and show in transcript
- [x] Milestone 7 — Voice Mode (local)
  - [x] Voice session UI
  - [x] Mock transcript stream fallback
  - [x] TTS playback
  - [x] Save transcript to messages
  - [x] Voice selection UI
- [x] Milestone 8 — Settings polish
  - [x] Theme/language selector
  - [x] Default model selection + last model
  - [x] About/version
  - [x] Accessibility + haptics pass
- [x] Milestone 9 — Final polish pass
  - [x] Micro-animations and error states
  - [x] Device QA fixes
