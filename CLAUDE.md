# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

TABAI is a premium multi-model AI assistant with three platforms: web frontend, Node.js backend, and native iOS app. Production runs on a single domain (ai.gravitilabs.com) with Hetzner hosting and Cloudflare DNS.

## Infrastructure

- **Hetzner server:** Hosts backend (Node.js + PM2) and static frontend (Nginx)
- **Cloudflare DNS:** Manages gravitilabs.com DNS, proxied to Hetzner
- **Database:** SQLite via better-sqlite3 (local on Hetzner)
- **Domain:** ai.gravitilabs.com → Hetzner (Nginx reverse proxy)
- **Email:** Resend (tabai@gravitilabs.com)

## Architecture

```
Browser → ai.gravitilabs.com (Cloudflare DNS → Hetzner)
         → Nginx → /* static assets (Next.js export)
         → Nginx → /api/* → Node.js :3001 (Hono + SQLite)
         → OpenRouter (model list + inference streaming)
         → fal.ai (image/video generation)
```

Three active projects:
- **web/** — Next.js 14 static export frontend (React 18, TypeScript, Zod)
- **backend/** — Node.js API server (Hono + Chanfana for OpenAPI 3.1, SQLite)
- **ios/TABAI/** — SwiftUI 17+ native iOS app

## Common Commands

### Frontend (web/)
```bash
cd web && npm install
npm run dev          # Dev server on :3000
npm run build        # Static export → .next-build/
npm run lint         # ESLint
```

### Backend (backend/)
```bash
cd backend && npm install
npm run dev          # Local dev on :3001
npm run migrate      # Apply SQLite migrations
npm run start        # Production server
```

### iOS
```bash
./scripts/generate-ios-project.sh   # Generate Xcode project
./scripts/build-ios-sim.sh          # Build for simulator
```

## Key Technical Details

- **Auth**: Cookie-based sessions (secure HttpOnly). All frontend API calls use `credentials: "include"`. CSRF double-submit cookie pattern.
- **API base URL resolution** (frontend): `meta[name="tai-api-base"]` → `NEXT_PUBLIC_TAI_API_BASE_URL` → empty string (same-origin).
- **Frontend path alias**: `@/*` maps to project root in tsconfig.
- **Backend routing**: Hono router with chanfana endpoint classes in `backend/src/endpoints/`. Each endpoint is a class with `schema` and `handle()`.
- **Database**: SQLite (better-sqlite3). Core tables: users, chats, messages, folders, models, user_permissions, user_settings, admin_audit_log.
- **CORS**: Allows `ai.gravitilabs.com` and `localhost:3000`.
- **Legal pages**: Served at `/tabai/*` paths (e.g., `/tabai/privacy`, `/tabai/terms`).
- **Email**: Resend API for verification, welcome, and password reset emails.
- **API docs** auto-generated at `/docs` endpoint.

## iOS App Structure

- **Core/**: Design system tokens, Keychain, localization (L10n), AppConfig, haptics
- **App/**: Entry point (TABAIApp.swift), RootView routing, AppEnvironment DI container
- **Features/**: Auth, Chat, Navigation, Settings, History — each with View + ViewModel
- Uses local persistence, Speech Recognition for voice input, photo/file attachments

## Master Scope & Workflow

**IMPORTANT:** Before starting any work, read `docs/milestones.md`. It contains the full milestone tracker, current progress, and task breakdown.

### How to Work with This Project

When the user says:
- **"planning"** or **"scope"** → Read docs/milestones.md, show current status, suggest next task
- **"M5A"**, **"M5B"**, **"M5C"**, etc. → Work on that specific milestone's tasks
- **"fix legal"** → Execute M5C tasks (replace placeholders, update company info)
- **"perplexity style"** or **"UX"** → Work on M5A-2 (Perplexity-style redesign)
- **"what's broken"** → Audit codebase against docs/milestones.md
- **"fal"** or **"image generation"** → Read docs/fal-ai-integration.md, work on M-FAL milestones

### Company Info (for legal docs)
- Email: tabai@gravitilabs.com
- Response time: within 3 business days
- Address: Sehit Sakir Elkovan cad. No:3 Atasehir Istanbul Turkiye
- Governing law: Turkiye
- Company: TABA TASARIM INSAAT A.S.
