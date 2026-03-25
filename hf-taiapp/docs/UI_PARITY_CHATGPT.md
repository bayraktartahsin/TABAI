# UI Parity: ChatGPT-like Behavior

## Completed parity changes

- Removed provider/OpenRouter selection from the visible UI.
  - Chat header now exposes only model selection.
  - Provider switching controls are hidden from chat/admin surfaces.
- Reworked header to ChatGPT-like minimal structure:
  - Left: sidebar toggle + new chat (icon buttons)
  - Center: model selector
  - Right: single user menu icon with Settings, Admin (role-gated), Sign out
- Replaced crowded text controls with compact icon actions:
  - Send, Stop, Regenerate, Copy, Attach, Mic, Sidebar search
  - All icon actions include `title` + `aria-label` via icon slot wrappers.
- Composer is sticky at the bottom and always reachable.
  - Left control group for attachment and mic
  - Right control group for send/stop/regenerate
- Sidebar behavior aligned with chat apps:
  - Smooth slide/overlay behavior on mobile
  - Search input inside sidebar
  - Desktop-open by default
- Message rendering tuned for streaming and performance:
  - Streaming row renders plain text + caret while generating
  - Completed rows support code block extraction with copy action
  - Message row component memoized to reduce unnecessary rerenders

## Streaming behavior parity

- True streaming route keeps token events flowing continuously.
- Client appends deltas directly into one active assistant draft message.
- Stop generation uses `AbortController` and ends immediately.
- Auto-scroll follows generation only while user is near the bottom.

## Notes

- Backend contracts were preserved.
- Auth, admin routing, and chat history persistence remain intact.
