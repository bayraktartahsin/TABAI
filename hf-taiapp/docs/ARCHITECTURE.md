# hf-taiapp Architecture

## Runtime model

hf-taiapp is a static Next.js app (output export) and contains no runtime server logic.

- UI is rendered in browser
- API calls target /api/* (same origin by default)
- Session uses HttpOnly cookie from tai-edge

## Production wiring

- Primary origin: https://ai.gravitilabs.com
- Frontend and backend share the same domain
- Backend API implementation: tai-edge Cloudflare Worker

## Key files

- app/layout.tsx: metadata + API base injection
- lib/tai/client.ts: REST client helpers
- lib/owui/client.ts: auth and stream helpers (name retained for compatibility)
- components/ui/AppShell.tsx: app orchestrator
- components/chat/ChatScreen.tsx: streaming chat UI

## Non-runtime code removed

- lib/server/*
- prisma/*
- app/api/* scaffolding
- startup.mjs
