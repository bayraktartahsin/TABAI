# TAI Production Architecture

Last updated: March 2026

## Final target

Single public product domain:

- https://ai.gravitilabs.com

This single domain serves:

- frontend application
- backend API under /api/*

## Runtime topology

Browser -> ai.gravitilabs.com
        -> frontend static assets
        -> /api/* handled by tai-edge Worker
        -> OpenRouter for model list + inference

## Components

### Frontend (hf-taiapp)

- Next.js static export frontend source
- Same-origin API calls by default (no hardcoded cross-origin requirement)
- Build remains static

### Backend (tai-edge)

- Cloudflare Worker runtime
- D1 database
- API routes remain under /api/*
- Auth session via secure HttpOnly cookie

### Model provider

- OpenRouter only in production
- Model sync: openrouter.ai/api/v1/models
- Inference streaming: openrouter.ai/api/v1/chat/completions

## Explicit non-production

- docker-compose files are local-only legacy tooling
- OpenWebUI/HuggingFace helper assets removed from production path
- hf-space legacy proxy removed

## Migration-safe behavior

- CORS allows ai.gravitilabs.com (+ ai.tahsinbayraktar.com for backward compat) and localhost:3000
- API paths remain stable under /api/*
