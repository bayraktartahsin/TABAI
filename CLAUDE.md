# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TAI is a premium multi-model chat application with three platforms: web frontend, serverless backend, and native iOS app. Production runs on a single domain (ai.gravitilabs.com) using Cloudflare infrastructure with OpenRouter as the sole model provider.

## Infrastructure

- **Hetzner server:** Hosts gravitilabs.com main site and other projects
- **Cloudflare DNS:** Manages all gravitilabs.com DNS records, proxies to Hetzner or Workers
- **Cloudflare Workers:** Hosts TAI backend (tai-edge) + static frontend assets
- **Cloudflare D1:** TAI database (SQLite on edge)
- **Domain:** ai.gravitilabs.com → Cloudflare Worker route (NOT Hetzner)
- **Worker URL:** tai-edge.billowing-recipe-00e2.workers.dev

## Architecture

```
Browser → ai.gravitilabs.com (Cloudflare DNS → Worker route)
         → static assets (Next.js export, served by Worker)
         → /api/* → tai-edge Worker → D1 database
         → OpenRouter (model list + inference streaming)
         → fal.ai (image/video generation)
```

Three active projects:
- **hf-taiapp/** — Next.js 14 static export frontend (React 18, TypeScript, Zod)
- **tai-edge/** — Cloudflare Worker backend (Hono + Chanfana for OpenAPI 3.1, D1 database)
- **ios/TAI/** — SwiftUI 17+ native iOS app

## Common Commands

### Frontend (hf-taiapp/)
```bash
cd hf-taiapp && npm install
npm run dev          # Dev server on :3000
npm run build        # Static export → .next-build/
npm run lint         # ESLint
```

### Backend (tai-edge/)
```bash
cd tai-edge && npm install
npx wrangler dev     # Local dev on :8787 (Swagger at /docs)
npx wrangler deploy  # Deploy to Cloudflare
npx wrangler types   # Generate TypeScript bindings from wrangler.jsonc
```

### Database Migrations
```bash
cd tai-edge
npx wrangler d1 migrations apply tai-edge-prod --local   # Apply locally
npx wrangler d1 migrations apply tai-edge-prod --remote   # Apply to production
```
Migration files are in `tai-edge/migrations/` (numbered 0001–0008).

### iOS
```bash
./scripts/generate_ios_project.sh   # Generate Xcode project
./scripts/build_ios_sim.sh          # Build for simulator
```

## Key Technical Details

- **Auth**: Cookie-based sessions (secure HttpOnly). All frontend API calls use `credentials: "include"`.
- **API base URL resolution** (frontend): `window.__TAI_API_BASE_URL__` → `NEXT_PUBLIC_TAI_API_BASE_URL` → `TAI_API_BASE_URL` → empty string (same-origin).
- **Frontend path alias**: `@/*` maps to project root in tsconfig.
- **Backend routing**: Hono router with chanfana endpoint classes in `tai-edge/src/endpoints/`. Each endpoint is a class with `schema` and `handle()`.
- **Database**: Cloudflare D1 (SQLite). Core tables: users, chats, messages, folders, models, user_permissions, user_settings, admin_audit_log.
- **CORS**: Allows `ai.gravitilabs.com` (+ `ai.tahsinbayraktar.com` for backward compat) and `localhost:3000`.
- **Legal pages**: Served at `/tabai/*` paths (e.g., `/tabai/privacy`, `/tabai/terms`). Old root paths redirect.
- **Docker-compose files** in repo root are local-only legacy tooling, not used in production.
- **API docs** auto-generated at `/docs` endpoint on the worker.

## iOS App Structure

- **Core/**: Design system tokens, Keychain, localization (L10n), AppConfig, haptics
- **App/**: Entry point (TABAIApp.swift), RootView routing, AppEnvironment DI container
- **Features/**: Auth, Chat, Navigation, Settings, History — each with View + ViewModel
- Uses local persistence, Speech Recognition for voice input, photo/file attachments

## Master Scope & Workflow

**IMPORTANT:** Before starting any work, read `TAI_MASTER_SCOPE.md` in the project root. It contains the full milestone tracker, current progress, and task breakdown.

### Active Milestones (priority order)
1. **M5C** — Legal placeholder fixes (CRITICAL, blocks App Store)
2. **M5A** — iOS production UX stabilization (~75% done)
3. **M5B** — iOS release hardening (after M5A)
4. **M6** — Android fast port (after iOS ships)

### How to Work with This Project

When the user says:
- **"planning"** or **"scope"** → Read TAI_MASTER_SCOPE.md, show current status, suggest next task
- **"M5A"**, **"M5B"**, **"M5C"**, etc. → Work on that specific milestone's tasks
- **"fix legal"** → Execute M5C tasks (replace placeholders, update company info)
- **"perplexity style"** or **"UX"** → Work on M5A-2 (Perplexity-style redesign)
- **"what's broken"** → Audit codebase against TAI_MASTER_SCOPE.md
- **"update scope"** → Update TAI_MASTER_SCOPE.md with completed items
- **"M-FAL-1"**, **"M-FAL-2"**, etc. → Work on fal.ai integration milestones (read FAL_AI_INTEGRATION_PLAN.md)
- **"fal"** or **"image generation"** → Read FAL_AI_INTEGRATION_PLAN.md, work on M-FAL milestones

### Design Reference (Perplexity-Style)
The target UX is Perplexity AI:
- Clean, search-first home with "Ask anything" prompt
- Answer cards (not chat bubbles) with clean typography
- Minimal chrome, fast model switching
- Follow-up suggestions after each answer
- Bottom composer bar (pill-shaped, minimal)

### Company Info (for legal docs)
- Email: support@tahsinbayraktar.com
- Response time: within 3 business days
- Address: Şehit Şakir Elkovan cad. No:3 Ataşehir Istanbul Türkiye
- Governing law: Türkiye
- Company: TABA TASARIM İNŞAAT A.Ş.
