/**
 * In-memory cache that replaces Cloudflare Workers' caches.default API.
 * Used by getCachedJson / storeCachedJson / invalidateUserCaches in tai.ts.
 */

const store = new Map<string, { response: Response; expiresAt: number }>();
const DEFAULT_TTL = 300_000; // 5 minutes

export const memoryCache = {
	async match(request: Request): Promise<Response | undefined> {
		const key = request.url;
		const entry = store.get(key);
		if (!entry) return undefined;
		if (Date.now() > entry.expiresAt) {
			store.delete(key);
			return undefined;
		}
		return entry.response.clone();
	},

	async put(request: Request, response: Response): Promise<void> {
		store.set(request.url, {
			response: response.clone(),
			expiresAt: Date.now() + DEFAULT_TTL,
		});
	},

	async delete(request: Request): Promise<boolean> {
		return store.delete(request.url);
	},
};
