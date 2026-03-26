# TABAI

Premium multi-model AI assistant — web, iOS, and Android.

## Production

- **URL:** https://ai.gravitilabs.com
- **Backend:** Hetzner server (Node.js + PM2 + Nginx)
- **Database:** SQLite via better-sqlite3
- **Models:** OpenRouter (inference + model list)
- **Media:** fal.ai (image/video generation)
- **Email:** Resend (tabai@gravitilabs.com)
- **DNS:** Cloudflare → Hetzner

## Project Structure

```
backend/     → Node.js API server (Hono + SQLite)
web/         → Next.js 14 static export frontend
ios/TABAI/   → SwiftUI native iOS app
android/     → Android app (Kotlin)
assets/      → App icon, logos
docs/        → Architecture, milestones, integration plans
scripts/     → Build and project generation scripts
```

## Quick Start

### Frontend

```bash
cd web && npm install
npm run dev          # Dev server on :3000
npm run build        # Static export → .next-build/
```

### Backend

```bash
cd backend && npm install
npm run dev          # Local dev on :3001
npm run migrate      # Apply SQLite migrations
npm run start        # Production server
```

### iOS

```bash
./scripts/build-ios-sim.sh          # Build for simulator
./scripts/generate-ios-project.sh   # Generate Xcode project
```

## Deployment

Backend runs on Hetzner via PM2. Nginx serves the static frontend and reverse-proxies `/api/*` to Node.js on port 3001.

API docs are auto-generated at `/docs`.
