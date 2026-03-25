# Found Endpoints and Settings (Workspace Scan)

Scan date: 2026-02-19

## Summary
- No `.env*`, `docker-compose*`, proxy configs (nginx/caddy), `wrangler.toml`, `vercel.json`, or `next.config.*` files found in this repo.
- No server-side OpenWebUI/OpenRouter config files present in this repo.
- Only iOS-side OpenWebUI wiring exists here.

## Matches (file + snippet)

### Base URL / API key references
- `TAI/Core/Config/AppConfig.swift`
  - `static let openWebUIBaseURL: String = "https://tai.tahsinbayraktar.com"`
  - `static let openWebUIAPIKey: String? = Bundle.main.infoDictionary?["OPENWEBUI_API_KEY"] as? String`

### OpenWebUI discovery / paths (iOS)
- `TAI/Services/OpenWebUI/OpenWebUIDiscovery.swift`
  - candidates: `openapi.json`, `api/v1/openapi.json`, `openwebui/openapi.json`, `open-webui/openapi.json`, etc.

### OpenWebUI routes (iOS)
- `TAI/Services/OpenWebUI/OpenWebUIRoutes.swift`
  - `apiRoot(baseURL: baseURL)` + `models`, `auths/signin`, `auths/me`, `chats`, `chat/completions`, `chat/stream`.

### Models config
- `TAI/Models/ModelCatalog.json`
  - `"models": []`
- `TAI/Models/ModelCatalog.swift`
  - `struct ModelCatalog { let models: [Model] }`

### Docs
- `TAI/Docs/DEVLOG.md`
  - Notes about earlier OpenWebUI integration steps and endpoints for HF deployment.

## What’s missing (not found)
- No OpenWebUI/OpenRouter settings in repo config files.
- No provider definitions or model lists outside the app bundle.
- No Cloudflare, HuggingFace Space, or backend runtime configs in this repo.

## Conclusion
The repository only contains the iOS app’s OpenWebUI integration code. Backend/runtime configuration appears to live outside this repo. iOS must rely on discovery or explicitly provided base URL + API settings.
