# TAI

TAI production architecture is Cloudflare-native and OpenRouter-only.

## Production

- Primary product origin: https://ai.gravitilabs.com
- Frontend app: served at the same origin
- Backend API: same origin under /api/*
- Backend runtime: Cloudflare Worker + D1 (project: tai-edge)
- Model provider: OpenRouter only

No production runtime dependency exists on OpenWebUI, Hugging Face, or Ollama.

## Active projects

- hf-taiapp: frontend source (Next.js static export)
- tai-edge: backend API (Cloudflare Worker + D1)
- ios/TAI: iOS app source

## Local development

Frontend:

```bash
cd hf-taiapp
npm install
npm run dev
```

Backend:

```bash
cd tai-edge
npm install
npx wrangler dev
```

## Deployment

Frontend build artifacts:

```bash
cd hf-taiapp
npm run build
```

Backend deploy:

```bash
cd tai-edge
npx wrangler deploy
```

## Notes

- docker-compose files in repository are local-only legacy tooling.
- API docs are served by the worker at /docs.
