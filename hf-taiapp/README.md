# TAI Web (hf-taiapp)

Frontend source for TAI.

## Production target

- Primary origin: https://ai.gravitilabs.com
- API path: /api/* on the same origin
- Backend implementation for /api/*: tai-edge Cloudflare Worker

## API base URL behavior

Runtime resolution order:

1. window.__TAI_API_BASE_URL__ (injected by layout)
2. NEXT_PUBLIC_TAI_API_BASE_URL
3. TAI_API_BASE_URL
4. Empty fallback (same-origin /api/*)

This means single-domain deployment works by default with no API base override.

## Local development

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

Build output is static and prepared for Cloudflare Pages deployment.
