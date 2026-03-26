# TABAI Web Architecture

## Runtime Model

Static Next.js app (output export) with no runtime server logic.

- UI rendered in browser
- API calls target /api/* (same origin by default)
- Session uses HttpOnly cookie from backend

## Production Wiring

- Origin: https://ai.gravitilabs.com
- Frontend and backend share the same domain
- Backend: Node.js (Hono) behind Nginx reverse proxy

## Key Files

- app/layout.tsx — metadata + API base injection
- lib/tai/client.ts — REST client helpers
- lib/owui/client.ts — auth and stream helpers (name retained for compatibility)
- components/ui/AppShell.tsx — app orchestrator
- components/chat/ChatScreen.tsx — streaming chat UI
