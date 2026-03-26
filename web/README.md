# TABAI Web

Frontend source for TABAI — Next.js 14 static export.

## Production

- Origin: https://ai.gravitilabs.com
- API: /api/* (same origin, proxied to backend by Nginx)

## API Base URL Resolution

Runtime resolution order:

1. `window.__TAI_API_BASE_URL__` (injected by layout)
2. `NEXT_PUBLIC_TAI_API_BASE_URL`
3. `TAI_API_BASE_URL`
4. Empty fallback (same-origin /api/*)

Single-domain deployment works by default with no override needed.

## Development

```bash
npm install
npm run dev     # :3000
npm run build   # Static export → .next-build/
```
