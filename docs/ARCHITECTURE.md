# TABAI Production Architecture

Last updated: March 2026

## Domain

Single public product domain: https://ai.gravitilabs.com

This single domain serves the frontend application and backend API under /api/*.

## Runtime Topology

```
Browser → ai.gravitilabs.com (Cloudflare DNS → Hetzner)
       → Nginx → /* static assets (Next.js export)
       → Nginx → /api/* → Node.js :3001 (Hono + SQLite)
       → OpenRouter (model list + inference streaming)
       → fal.ai (image/video generation)
```

## Components

### Frontend (web/)

- Next.js static export
- Same-origin API calls by default
- Build output: .next-build/

### Backend (backend/)

- Node.js + Hono framework
- SQLite via better-sqlite3
- PM2 process manager
- API routes under /api/*
- Auth: secure HttpOnly cookie sessions

### Model Provider

- OpenRouter only in production
- Model sync: openrouter.ai/api/v1/models
- Inference streaming: openrouter.ai/api/v1/chat/completions

## Notes

- docker-compose files are local-only legacy tooling
- CORS allows ai.gravitilabs.com (+ ai.tahsinbayraktar.com for backward compat) and localhost:3000
- API paths remain stable under /api/*
