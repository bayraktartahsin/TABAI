# Manual QA Checklist: Streaming + UI

## A) Header and controls

- [ ] Header shows only: sidebar toggle, new chat, model selector, user menu icon.
- [ ] No provider/OpenRouter selector appears in chat UI.
- [ ] User menu contains: Settings, Admin (admin only), Sign out.

## B) Composer and icons

- [ ] Composer is sticky and visible at bottom on desktop and mobile.
- [ ] Icon buttons show tooltips on hover and have accessible labels.
- [ ] Attach button opens menu for image/file uploads.
- [ ] Mic button starts/stops browser speech input where supported.

## C) Streaming behavior

- [ ] Sending a prompt creates assistant draft immediately (no long blank wait).
- [ ] Assistant response appears incrementally token-by-token.
- [ ] Stop button cancels generation immediately.
- [ ] Regenerate starts a new streamed response.
- [ ] Continue generating appears when finish reason indicates truncation.

## D) Scroll + performance

- [ ] Chat auto-scroll follows stream when user is at bottom.
- [ ] If user scrolls up, stream continues without forced jump-to-bottom.
- [ ] Long chats remain smooth during streaming.

## E) Attachments + model gating

- [ ] Image attachments are blocked on non-vision models with clear message.
- [ ] Vision-capable model allows image payload in request path.
- [ ] Removing attachment chips works correctly.

## F) Role and account

- [ ] Non-admin user does not see Admin option in user menu.
- [ ] Sign out clears session and returns to login screen.
- [ ] After login, chat history namespace follows signed-in user identity.

## G) Responsive + motion

- [ ] Sidebar open/close is smooth and non-janky.
- [ ] Message entry animation is subtle and stable.
- [ ] Motion reduces appropriately when OS `prefers-reduced-motion` is enabled.
