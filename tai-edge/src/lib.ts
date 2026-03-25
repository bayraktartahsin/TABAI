import { z } from "zod";
import type { AppContext } from "./types";

export type Role = "ADMIN" | "USER";
export type UserStatus = "ENABLED" | "FROZEN" | "DELETED";
export type PlanTier = "free" | "starter" | "pro" | "power";
export type EntitlementSource = "free" | "apple" | "google" | "admin" | "web";
export type EntitlementStatus = "active" | "inactive" | "grace" | "cancelled" | "expired";
export type ModelCategory = "free-basic" | "fast-everyday" | "premium-reasoning" | "premium-creative" | "image-vision" | "image-generation" | "hidden-internal";

export type EntitlementRecord = {
	id: string;
	userId: string;
	planTier: PlanTier;
	source: EntitlementSource;
	status: EntitlementStatus;
	startAt: string;
	expiresAt: string | null;
	autoRenew: boolean;
	externalProductId: string | null;
	externalOriginalTransactionId: string | null;
	lastValidatedAt: string | null;
	updatedAt: string;
};

export type UserProfile = {
	id: string;
	email: string;
	username: string;
	displayName: string | null;
	role: Role;
	status: UserStatus;
	planTier: PlanTier;
	emailVerified: boolean;
	verificationRequired: boolean;
	entitlement: EntitlementRecord | null;
	lastActiveAt: string | null;
	createdAt: string | null;
};

export type SettingsRecord = {
	theme: string;
	language: string;
	notificationsEnabled: boolean;
	voiceSessionEnabled: boolean;
};

export type ProviderRecord = {
	id: string;
	name: string;
	slug: string;
	type: string;
	endpointUrl: string;
	enabled: boolean;
	models?: Array<{ id: string; displayName: string; enabled: boolean }>;
	secrets?: Array<{ id: string; kind: string; updatedAt: string }>;
};

export type ModelRecord = {
	id: string;
	providerId: string;
	slug: string;
	providerModelId: string;
	displayName: string;
	logoUrl?: string | null;
	description?: string | null;
	enabled: boolean;
	supportsStreaming: boolean;
	supportsTextChat?: boolean;
	supportsVision: boolean;
	supportsReasoning?: boolean;
	supportsImageGeneration?: boolean;
	vendor?: string | null;
	capabilities: string[];
	verified: boolean;
	verificationStatus: "verified" | "unverified" | "failed";
	contextLength?: number | null;
	pricingTier?: "free" | "paid" | null;
	category?: ModelCategory;
	requiredPlanTier?: PlanTier;
	canAccess?: boolean;
	lockReason?: string | null;
	provider: ProviderRecord;
};

export type FolderRecord = {
	id: string;
	name: string;
	color?: string | null;
	createdAt: string;
	updatedAt: string;
};

export type MessageRecord = {
	id: string;
	chatId: string;
	role: string;
	content: string;
	sequence: number;
	isDeleted: boolean;
	createdAt: string;
	updatedAt: string;
};

export type ChatRecord = {
	id: string;
	userId: string;
	folderId: string | null;
	title: string;
	modelId: string | null;
	isPinned: boolean;
	isDeleted: boolean;
	createdAt: string;
	updatedAt: string;
	folder: FolderRecord | null;
	model: ModelRecord | null;
	messages: MessageRecord[];
};

type SessionPayload = {
	sub: string;
	email: string;
	role: Role;
	sv: number;
	iat: number;
	exp: number;
};

type D1Row = Record<string, unknown>;

const DEFAULT_SETTINGS: SettingsRecord = {
	theme: "system",
	language: "en",
	notificationsEnabled: true,
	voiceSessionEnabled: false,
};

const PLAN_ORDER: Record<PlanTier, number> = {
	free: 0,
	starter: 1,
	pro: 2,
	power: 3,
};

function normalizePlanTier(value: unknown): PlanTier {
	if (value === "starter" || value === "pro" || value === "power") return value;
	return "free";
}

function normalizeEntitlementSource(value: unknown): EntitlementSource {
	if (value === "apple" || value === "google" || value === "admin" || value === "web") return value;
	return "free";
}

function normalizeEntitlementStatus(value: unknown): EntitlementStatus {
	if (value === "active" || value === "grace" || value === "cancelled" || value === "expired") return value;
	return "inactive";
}

function mapEntitlement(row: EntitlementRow | null): EntitlementRecord | null {
	if (!row) return null;
	return {
		id: row.id,
		userId: row.user_id,
		planTier: normalizePlanTier(row.plan_tier),
		source: normalizeEntitlementSource(row.source),
		status: normalizeEntitlementStatus(row.status),
		startAt: row.start_at,
		expiresAt: row.expires_at,
		autoRenew: boolFrom(row.auto_renew),
		externalProductId: row.external_product_id,
		externalOriginalTransactionId: row.external_original_transaction_id,
		lastValidatedAt: row.last_validated_at,
		updatedAt: row.updated_at,
	};
}

const PROVIDER: ProviderRecord = {
	id: "openrouter",
	name: "OpenRouter",
	slug: "openrouter",
	type: "OPENAI_COMPATIBLE",
	endpointUrl: "https://openrouter.ai/api/v1",
	enabled: true,
	secrets: [],
	models: [],
};

export const chatCreateSchema = z.object({
	title: z.string().trim().min(1).max(200).optional(),
	folderId: z.string().trim().nullable().optional(),
	modelId: z.string().trim().nullable().optional(),
});

export const chatPatchSchema = z.object({
	title: z.string().trim().min(1).max(200).optional(),
	folderId: z.string().trim().nullable().optional(),
	modelId: z.string().trim().nullable().optional(),
	isPinned: z.boolean().optional(),
});

export const messageCreateSchema = z.object({
	role: z.string().trim().min(1),
	content: z.string(),
});

export const settingsPatchSchema = z.object({
	theme: z.string().trim().min(1).max(32).optional(),
	language: z.string().trim().min(1).max(32).optional(),
	notificationsEnabled: z.boolean().optional(),
	voiceSessionEnabled: z.boolean().optional(),
});

export const settingsAccountSchema = z.object({
	email: z.string().trim().email().optional(),
	currentPassword: z.string().min(1).optional(),
	password: z.string().min(8).optional(),
});

export const folderCreateSchema = z.object({
	name: z.string().trim().min(1).max(120),
	color: z.string().trim().max(32).optional(),
});

export const folderPatchSchema = z.object({
	name: z.string().trim().min(1).max(120).optional(),
	color: z.string().trim().nullable().optional(),
});

export const signinSchema = z.object({
	email: z.string().trim().email(),
	password: z.string().min(1),
});

export const signupSchema = z.object({
	email: z.string().trim().email(),
	password: z.string().min(8),
	username: z.string().trim().min(3).max(80).optional(),
	displayName: z.string().trim().max(120).optional(),
});

export const verifyTokenSchema = z.object({
	token: z.string().trim().min(20),
});

export const verificationRequestSchema = z.object({
	email: z.string().trim().email(),
});

export const passwordResetRequestSchema = z.object({
	email: z.string().trim().email(),
});

export const passwordResetConfirmSchema = z.object({
	token: z.string().trim().min(20),
	newPassword: z.string().min(8),
});

export const streamSchema = z.object({
	model: z.string().trim().min(1),
	chatId: z.string().trim().optional(),
	messages: z.array(
		z.object({
			role: z.enum(["system", "user", "assistant"]),
			content: z.string(),
		}),
	).min(1),
	maxTokens: z.number().int().positive().max(8192).optional(),
	attachments: z.array(
		z.discriminatedUnion("type", [
			z.object({
				type: z.literal("image_url"),
				name: z.string().trim().min(1).max(180).optional(),
				mime: z.string().trim().min(1).max(64).optional(),
				size: z.number().int().nonnegative().max(8 * 1024 * 1024).optional(),
				image_url: z.object({
					url: z.string().trim().min(1).max(12 * 1024 * 1024),
				}),
			}),
			z.object({
				type: z.literal("text_file"),
				name: z.string().trim().min(1).max(180),
				mime: z.string().trim().min(1).max(64),
				size: z.number().int().nonnegative().max(1 * 1024 * 1024),
				text: z.string().max(120000),
			}),
		]),
	).max(6).optional(),
});

export const adminUserCreateSchema = z.object({
	email: z.string().trim().email(),
	username: z.string().trim().min(1).max(80),
	displayName: z.string().trim().max(120).optional(),
	password: z.string().min(8),
	role: z.enum(["ADMIN", "USER"]).default("USER"),
	planTier: z.enum(["free", "starter", "pro", "power"]).optional(),
});

export const adminUserPatchSchema = z.object({
	email: z.string().trim().email().optional(),
	username: z.string().trim().min(1).max(80).optional(),
	displayName: z.string().trim().max(120).nullable().optional(),
	password: z.string().min(8).optional(),
	status: z.enum(["ENABLED", "FROZEN", "DELETED"]).optional(),
	planTier: z.enum(["free", "starter", "pro", "power"]).optional(),
});

export const adminEntitlementPatchSchema = z.object({
	planTier: z.enum(["free", "starter", "pro", "power"]),
	source: z.enum(["free", "apple", "google", "admin", "web"]).default("admin"),
	status: z.enum(["active", "inactive", "grace", "cancelled", "expired"]).default("active"),
	startAt: z.string().datetime().optional(),
	expiresAt: z.string().datetime().nullable().optional(),
	autoRenew: z.boolean().optional(),
	externalProductId: z.string().trim().max(180).nullable().optional(),
	externalOriginalTransactionId: z.string().trim().max(260).nullable().optional(),
});

export const storeEntitlementSyncSchema = z.discriminatedUnion("provider", [
	z.object({
		provider: z.literal("apple"),
		productId: z.string().trim().max(180).optional(),
		transactionId: z.string().trim().min(1).max(260),
		originalTransactionId: z.string().trim().max(260).optional(),
		signedTransactionInfo: z.string().trim().max(14000).optional(),
		signedRenewalInfo: z.string().trim().max(14000).optional(),
		environment: z.enum(["production", "sandbox"]).default("production"),
		rawPayload: z.record(z.any()).optional(),
	}),
	z.object({
		provider: z.literal("google"),
		packageName: z.string().trim().min(1).max(220),
		productId: z.string().trim().min(1).max(180),
		purchaseToken: z.string().trim().min(1).max(1600),
		orderId: z.string().trim().max(260).optional(),
		rawPayload: z.record(z.any()).optional(),
	}),
]);

export type AppleStoreEntitlementSyncInput = {
	provider: "apple";
	productId?: string;
	transactionId: string;
	originalTransactionId?: string;
	signedTransactionInfo?: string;
	signedRenewalInfo?: string;
	environment: "production" | "sandbox";
	rawPayload?: Record<string, any>;
};

export type GoogleStoreEntitlementSyncInput = {
	provider: "google";
	packageName: string;
	productId: string;
	purchaseToken: string;
	orderId?: string;
	rawPayload?: Record<string, any>;
};

export type StoreEntitlementSyncInput = AppleStoreEntitlementSyncInput | GoogleStoreEntitlementSyncInput;

export const permissionsPutSchema = z.object({
	modelIds: z.array(z.string()).default([]),
});

export const adminModelPostSchema = z.object({
	action: z.string().optional(),
	providerId: z.string().optional(),
	slug: z.string().optional(),
	providerModelId: z.string().optional(),
	displayName: z.string().optional(),
	enabled: z.boolean().optional(),
	supportsStreaming: z.boolean().optional(),
	supportsVision: z.boolean().optional(),
});

export const adminModelPatchSchema = z.object({
	displayName: z.string().trim().min(1).max(160).optional(),
	enabled: z.boolean().optional(),
});

function nowIso() {
	return new Date().toISOString();
}

function randomId() {
	return crypto.randomUUID();
}

function boolFrom(value: unknown) {
	return Number(value ?? 0) === 1;
}

function envString(env: Env, key: string) {
	const value = (env as unknown as Record<string, unknown>)[key];
	return typeof value === "string" ? value : "";
}

function envBool(env: Env, key: string, fallback = false) {
	const raw = envString(env, key).trim().toLowerCase();
	if (!raw) return fallback;
	return raw === "1" || raw === "true" || raw === "yes" || raw === "on";
}

function envInt(env: Env, key: string, fallback: number, min: number, max: number) {
	const raw = envString(env, key).trim();
	if (!raw) return fallback;
	const parsed = Number.parseInt(raw, 10);
	if (!Number.isFinite(parsed)) return fallback;
	return Math.max(min, Math.min(max, parsed));
}

export function corsHeaders(origin: string | null) {
	const allowedOrigins = new Set([
		"https://ai.gravitilabs.com",
		// Legacy domain retained for transition safety — remove later.
		"https://ai.tahsinbayraktar.com",
		"http://localhost:3000",
	]);
	const headers = new Headers();
	if (origin && allowedOrigins.has(origin)) {
		headers.set("Access-Control-Allow-Origin", origin);
		headers.set("Access-Control-Allow-Credentials", "true");
		headers.set("Vary", "Origin");
	}
	headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
	headers.set("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE, OPTIONS");
	return headers;
}

export function applyCors(c: AppContext) {
	const origin = c.req.header("origin") ?? null;
	const headers = corsHeaders(origin);
	headers.forEach((value, key) => c.header(key, value));
}

export function preflight(c: AppContext) {
	const headers = corsHeaders(c.req.header("origin") ?? null);
	return new Response(null, { status: 204, headers });
}

export function jsonError(c: AppContext, status: number, error: string, code?: string) {
	applyCors(c);
	return c.json(code ? { error, code } : { error }, status);
}

function parseCookies(header: string | null) {
	const out = new Map<string, string>();
	if (!header) return out;
	for (const part of header.split(/;\s*/)) {
		const index = part.indexOf("=");
		if (index <= 0) continue;
		out.set(part.slice(0, index), decodeURIComponent(part.slice(index + 1)));
	}
	return out;
}

function base64UrlEncode(bytes: Uint8Array) {
	let binary = "";
	for (const byte of bytes) binary += String.fromCharCode(byte);
	return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function base64UrlEncodeText(value: string) {
	return base64UrlEncode(new TextEncoder().encode(value));
}

function base64UrlDecodeText(value: string) {
	const base64 = value.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(value.length / 4) * 4, "=");
	const binary = atob(base64);
	const bytes = new Uint8Array(binary.length);
	for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
	return new TextDecoder().decode(bytes);
}

async function hmac(secret: string, payload: string) {
	const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
	const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
	return base64UrlEncode(new Uint8Array(signature));
}

function pemToArrayBuffer(pemRaw: string) {
	const pem = pemRaw.replace(/\\n/g, "\n").trim();
	const body = pem
		.replace(/-----BEGIN [A-Z ]+-----/g, "")
		.replace(/-----END [A-Z ]+-----/g, "")
		.replace(/\s+/g, "");
	const binary = atob(body);
	const bytes = new Uint8Array(binary.length);
	for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
	return bytes.buffer;
}

async function signJwtRs256(header: Record<string, unknown>, payload: Record<string, unknown>, privateKeyPem: string) {
	const encodedHeader = base64UrlEncodeText(JSON.stringify(header));
	const encodedPayload = base64UrlEncodeText(JSON.stringify(payload));
	const toSign = `${encodedHeader}.${encodedPayload}`;
	const key = await crypto.subtle.importKey(
		"pkcs8",
		pemToArrayBuffer(privateKeyPem),
		{ name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
		false,
		["sign"],
	);
	const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(toSign));
	return `${toSign}.${base64UrlEncode(new Uint8Array(signature))}`;
}

class JwtSignError extends Error {
	readonly code: string;

	constructor(code: string, message: string) {
		super(message);
		this.code = code;
		this.name = "JwtSignError";
	}
}

function derLength(bytes: Uint8Array, index: number) {
	const first = bytes[index];
	if ((first & 0x80) === 0) return { length: first, bytesUsed: 1 };
	const count = first & 0x7f;
	if (count === 0 || count > 4) throw new JwtSignError("APPLE_JWT_SIG_FORMAT_INVALID", "Unsupported DER length encoding.");
	let length = 0;
	for (let i = 0; i < count; i += 1) {
		length = (length << 8) | bytes[index + 1 + i];
	}
	return { length, bytesUsed: 1 + count };
}

function normalizeEs256Component(component: Uint8Array) {
	let index = 0;
	while (index < component.length - 1 && component[index] === 0) index += 1;
	const trimmed = component.slice(index);
	if (trimmed.length > 32) {
		throw new JwtSignError("APPLE_JWT_SIG_FORMAT_INVALID", "ES256 signature component exceeds 32 bytes.");
	}
	const output = new Uint8Array(32);
	output.set(trimmed, 32 - trimmed.length);
	return output;
}

function toJoseEs256Signature(signature: ArrayBuffer) {
	const bytes = new Uint8Array(signature);
	if (bytes.length === 64) return bytes;

	// Convert ASN.1 DER ECDSA signature to JOSE R||S format.
	if (bytes.length < 8 || bytes[0] !== 0x30) {
		throw new JwtSignError("APPLE_JWT_SIG_FORMAT_INVALID", "Unexpected ECDSA signature format.");
	}

	let cursor = 1;
	const seq = derLength(bytes, cursor);
	cursor += seq.bytesUsed;
	if (cursor + seq.length !== bytes.length) {
		throw new JwtSignError("APPLE_JWT_SIG_FORMAT_INVALID", "DER sequence length mismatch.");
	}
	if (bytes[cursor] !== 0x02) {
		throw new JwtSignError("APPLE_JWT_SIG_FORMAT_INVALID", "DER signature missing R integer.");
	}
	cursor += 1;
	const rLen = derLength(bytes, cursor);
	cursor += rLen.bytesUsed;
	const r = bytes.slice(cursor, cursor + rLen.length);
	cursor += rLen.length;
	if (bytes[cursor] !== 0x02) {
		throw new JwtSignError("APPLE_JWT_SIG_FORMAT_INVALID", "DER signature missing S integer.");
	}
	cursor += 1;
	const sLen = derLength(bytes, cursor);
	cursor += sLen.bytesUsed;
	const s = bytes.slice(cursor, cursor + sLen.length);

	const jose = new Uint8Array(64);
	jose.set(normalizeEs256Component(r), 0);
	jose.set(normalizeEs256Component(s), 32);
	return jose;
}

async function signJwtEs256(header: Record<string, unknown>, payload: Record<string, unknown>, privateKeyPem: string) {
	const encodedHeader = base64UrlEncodeText(JSON.stringify(header));
	const encodedPayload = base64UrlEncodeText(JSON.stringify(payload));
	const toSign = `${encodedHeader}.${encodedPayload}`;

	let key: CryptoKey;
	try {
		key = await crypto.subtle.importKey(
			"pkcs8",
			pemToArrayBuffer(privateKeyPem),
			{ name: "ECDSA", namedCurve: "P-256" },
			false,
			["sign"],
		);
	} catch (error) {
		throw new JwtSignError("APPLE_JWT_KEY_IMPORT_FAILED", `Could not import Apple .p8 key: ${error instanceof Error ? error.message : String(error)}`);
	}

	let signature: ArrayBuffer;
	try {
		signature = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(toSign));
	} catch (error) {
		throw new JwtSignError("APPLE_JWT_SIGN_FAILED", `Failed to sign Apple JWT with ES256: ${error instanceof Error ? error.message : String(error)}`);
	}

	const joseSignature = toJoseEs256Signature(signature);
	return `${toSign}.${base64UrlEncode(joseSignature)}`;
}

function decodeJwtPayloadUnsafe(token: string) {
	const parts = token.split(".");
	if (parts.length < 2) return null;
	try {
		return JSON.parse(base64UrlDecodeText(parts[1]));
	} catch {
		return null;
	}
}

async function hashPassword(password: string) {
	const salt = crypto.getRandomValues(new Uint8Array(16));
	const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(password), "PBKDF2", false, ["deriveBits"]);
	const bits = await crypto.subtle.deriveBits(
		{ name: "PBKDF2", hash: "SHA-256", salt, iterations: 100000 },
		key,
		256,
	);
	return `pbkdf2$100000$${base64UrlEncode(salt)}$${base64UrlEncode(new Uint8Array(bits))}`;
}

async function verifyPassword(password: string, stored: string) {
	const [kind, iterRaw, saltRaw, hashRaw] = stored.split("$");
	if (kind !== "pbkdf2" || !iterRaw || !saltRaw || !hashRaw) return false;
	const iterations = Number(iterRaw);
	const saltBytes = Uint8Array.from(atob(saltRaw.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(saltRaw.length / 4) * 4, "=")), (char) => char.charCodeAt(0));
	const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(password), "PBKDF2", false, ["deriveBits"]);
	const bits = await crypto.subtle.deriveBits(
		{ name: "PBKDF2", hash: "SHA-256", salt: saltBytes, iterations },
		key,
		256,
	);
	return base64UrlEncode(new Uint8Array(bits)) === hashRaw;
}

function resolveSessionSecret(env: Env) {
	return env.TAI_SESSION_SECRET || env.TAI_ENCRYPTION_KEY || "tai-session-secret";
}

async function getSessionVersion(env: Env, userId: string) {
	const row = await queryFirst<{ session_version: number | null }>(
		env.DB,
		"SELECT session_version FROM users WHERE id = ? LIMIT 1",
		userId,
	);
	return Number(row?.session_version ?? 0);
}

export async function createSessionCookie(env: Env, user: UserProfile) {
	const sessionVersion = await getSessionVersion(env, user.id);
	const payload: SessionPayload = {
		sub: user.id,
		email: user.email,
		role: user.role,
		sv: sessionVersion,
		iat: Date.now(),
		exp: Date.now() + 1000 * 60 * 60 * 24 * 30,
	};
	const encoded = base64UrlEncodeText(JSON.stringify(payload));
	const signature = await hmac(resolveSessionSecret(env), encoded);
	return `${encoded}.${signature}`;
}

export async function parseSessionCookie(env: Env, token?: string | null) {
	if (!token) return null;
	const [encoded, signature] = token.split(".");
	if (!encoded || !signature) return null;
	const expected = await hmac(resolveSessionSecret(env), encoded);
	if (expected !== signature) return null;
	const payload = JSON.parse(base64UrlDecodeText(encoded)) as SessionPayload;
	if (payload.exp <= Date.now()) return null;
	const row = await queryFirst<UserRow>(
		env.DB,
		"SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE id = ? LIMIT 1",
		payload.sub,
	);
	if (!row || row.status !== "ENABLED") return null;
	// MVP: skip email verification check for session cookies — auto-verified on signup
	// if (!row.email_verified_at) return null;
	const expectedSessionVersion = Number(row.session_version ?? 0);
	if (Number(payload.sv ?? -1) !== expectedSessionVersion) return null;
	const idleTimeoutHours = envInt(env, "TAI_SESSION_IDLE_TIMEOUT_HOURS", 24 * 14, 1, 24 * 365);
	if (row.last_active_at) {
		const idleMs = Date.now() - Date.parse(row.last_active_at);
		if (Number.isFinite(idleMs) && idleMs > idleTimeoutHours * 60 * 60 * 1000) return null;
	}
	const entitlement = await getEffectiveEntitlementForUser(env, row.id);
	return mapUser(row, entitlement);
}

export async function requireUser(c: AppContext) {
	const token = parseCookies(c.req.header("cookie") ?? null).get("tai_session");
	const user = await parseSessionCookie(c.env, token);
	if (!user) return null;
	void exec(
		c.env.DB,
		"UPDATE users SET last_active_at = ?, updated_at = ? WHERE id = ? AND (last_active_at IS NULL OR last_active_at <= ?)",
		nowIso(),
		nowIso(),
		user.id,
		new Date(Date.now() - 1000 * 60 * 15).toISOString(),
	);
	return user;
}

export function setSessionHeader(c: AppContext, token: string) {
	const expDate = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toUTCString();
	c.header("Set-Cookie", `tai_session=${encodeURIComponent(token)}; Path=/; HttpOnly; Secure; SameSite=None; Max-Age=7776000; Expires=${expDate}`);
}

export function clearSessionHeader(c: AppContext) {
	c.header("Set-Cookie", "tai_session=; Path=/; HttpOnly; Secure; SameSite=None; Max-Age=0");
}

export function sanitizeUser(user: UserProfile) {
	return user;
}

async function queryFirst<T extends D1Row>(db: D1Database, sql: string, ...bindings: unknown[]) {
	const result = await db.prepare(sql).bind(...bindings).first<T>();
	return result ?? null;
}

async function queryAll<T extends D1Row>(db: D1Database, sql: string, ...bindings: unknown[]) {
	const result = await db.prepare(sql).bind(...bindings).all<T>();
	return (result.results ?? []) as T[];
}

async function exec(db: D1Database, sql: string, ...bindings: unknown[]) {
	return db.prepare(sql).bind(...bindings).run();
}

let securityTablesInitPromise: Promise<void> | null = null;
let bootstrapInitPromise: Promise<void> | null = null;
let entitlementTablesInitPromise: Promise<void> | null = null;

async function ensureSecurityTables(env: Env) {
	if (securityTablesInitPromise) return securityTablesInitPromise;
	securityTablesInitPromise = (async () => {
		await exec(
			env.DB,
			`CREATE TABLE IF NOT EXISTS rate_limits (
				bucket_key TEXT PRIMARY KEY,
				scope TEXT NOT NULL,
				identifier_hash TEXT NOT NULL,
				window_start_ms INTEGER NOT NULL,
				window_seconds INTEGER NOT NULL,
				count INTEGER NOT NULL,
				created_at TEXT NOT NULL,
				last_seen_at TEXT NOT NULL
			)`
		);
		await exec(
			env.DB,
			`CREATE TABLE IF NOT EXISTS rate_limit_events (
				id TEXT PRIMARY KEY,
				scope TEXT NOT NULL,
				identifier_hash TEXT NOT NULL,
				event_ms INTEGER NOT NULL,
				created_at TEXT NOT NULL
			)`
		);
		await exec(
			env.DB,
			`CREATE TABLE IF NOT EXISTS usage_events (
				id TEXT PRIMARY KEY,
				user_id TEXT,
				chat_id TEXT,
				model_id TEXT,
				endpoint TEXT NOT NULL,
				input_message_count INTEGER NOT NULL DEFAULT 0,
				input_chars INTEGER NOT NULL DEFAULT 0,
				max_tokens_requested INTEGER,
				output_chars INTEGER NOT NULL DEFAULT 0,
				status TEXT NOT NULL,
				finish_reason TEXT,
				ip_hash TEXT,
				created_at TEXT NOT NULL
			)`
		);
		await exec(
			env.DB,
			`CREATE TABLE IF NOT EXISTS auth_tokens (
				id TEXT PRIMARY KEY,
				type TEXT NOT NULL,
				user_id TEXT,
				email TEXT,
				token_hash TEXT NOT NULL,
				expires_at TEXT NOT NULL,
				used_at TEXT,
				created_at TEXT NOT NULL
			)`
		);
		await exec(
			env.DB,
			`CREATE TABLE IF NOT EXISTS usage_ledger (
				request_id TEXT PRIMARY KEY,
				user_id TEXT NOT NULL,
				model_id TEXT,
				endpoint TEXT NOT NULL,
				plan_tier TEXT NOT NULL,
				estimated_input_tokens INTEGER NOT NULL DEFAULT 0,
				reserved_output_tokens INTEGER NOT NULL DEFAULT 0,
				estimated_total_tokens INTEGER NOT NULL DEFAULT 0,
				estimated_cost_units INTEGER NOT NULL DEFAULT 0,
				actual_output_chars INTEGER NOT NULL DEFAULT 0,
				status TEXT NOT NULL,
				created_at TEXT NOT NULL,
				updated_at TEXT NOT NULL
			)`
		);
		await exec(
			env.DB,
			`CREATE TABLE IF NOT EXISTS active_streams (
				lease_id TEXT PRIMARY KEY,
				user_id TEXT NOT NULL,
				created_at TEXT NOT NULL,
				expires_at TEXT NOT NULL,
				updated_at TEXT NOT NULL
			)`
		);
		await exec(
			env.DB,
			`CREATE TABLE IF NOT EXISTS safety_events (
				id TEXT PRIMARY KEY,
				event_type TEXT NOT NULL,
				user_id TEXT,
				ip_hash TEXT,
				request_id TEXT,
				model_id TEXT,
				plan_tier TEXT,
				code TEXT NOT NULL,
				message TEXT NOT NULL,
				details_json TEXT,
				created_at TEXT NOT NULL
			)`
		);
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_rate_limits_scope_window ON rate_limits(scope, window_start_ms)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_rate_limit_events_scope_hash_ms ON rate_limit_events(scope, identifier_hash, event_ms)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_usage_events_user_created ON usage_events(user_id, created_at DESC)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_usage_events_endpoint_created ON usage_events(endpoint, created_at DESC)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_auth_tokens_type_email_created ON auth_tokens(type, email, created_at DESC)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_auth_tokens_type_user_created ON auth_tokens(type, user_id, created_at DESC)");
		await exec(env.DB, "CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_tokens_type_hash ON auth_tokens(type, token_hash)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_usage_ledger_user_created ON usage_ledger(user_id, created_at DESC)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_usage_ledger_status_created ON usage_ledger(status, created_at DESC)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_active_streams_user_expires ON active_streams(user_id, expires_at)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_safety_events_type_created ON safety_events(event_type, created_at DESC)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_safety_events_user_created ON safety_events(user_id, created_at DESC)");
	})();
	return securityTablesInitPromise;
}

async function ensureEntitlementTables(env: Env) {
	if (entitlementTablesInitPromise) return entitlementTablesInitPromise;
	entitlementTablesInitPromise = (async () => {
		await exec(
			env.DB,
			`CREATE TABLE IF NOT EXISTS user_entitlements (
				id TEXT PRIMARY KEY,
				user_id TEXT NOT NULL,
				plan_tier TEXT NOT NULL,
				source TEXT NOT NULL,
				status TEXT NOT NULL,
				start_at TEXT NOT NULL,
				expires_at TEXT,
				auto_renew INTEGER NOT NULL DEFAULT 0,
				external_product_id TEXT,
				external_original_transaction_id TEXT,
				last_validated_at TEXT,
				metadata_json TEXT,
				created_at TEXT NOT NULL,
				updated_at TEXT NOT NULL,
				FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
			)`
		);
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_entitlements_user_updated ON user_entitlements(user_id, updated_at DESC)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_entitlements_user_status_dates ON user_entitlements(user_id, status, start_at, expires_at)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_entitlements_source_original_tx ON user_entitlements(source, external_original_transaction_id)");
		await exec(
			env.DB,
			`CREATE TABLE IF NOT EXISTS store_verification_attempts (
				id TEXT PRIMARY KEY,
				user_id TEXT NOT NULL,
				provider TEXT NOT NULL,
				outcome TEXT NOT NULL,
				code TEXT,
				transaction_hash TEXT,
				purchase_token_hash TEXT,
				payload_hash TEXT,
				details_json TEXT,
				created_at TEXT NOT NULL,
				FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
			)`
		);
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_store_verify_user_created ON store_verification_attempts(user_id, created_at DESC)");
		await exec(env.DB, "CREATE INDEX IF NOT EXISTS idx_store_verify_provider_created ON store_verification_attempts(provider, created_at DESC)");
	})();
	return entitlementTablesInitPromise;
}

async function getEffectiveEntitlementForUser(env: Env, userId: string) {
	await ensureEntitlementTables(env);
	const now = nowIso();
	const row = await queryFirst<EntitlementRow>(
		env.DB,
		`SELECT id, user_id, plan_tier, source, status, start_at, expires_at, auto_renew, external_product_id, external_original_transaction_id, last_validated_at, metadata_json, created_at, updated_at
		 FROM user_entitlements
		 WHERE user_id = ?
		   AND start_at <= ?
		   AND status IN ('active', 'grace')
		   AND (expires_at IS NULL OR expires_at > ?)
		 ORDER BY CASE status WHEN 'active' THEN 0 ELSE 1 END, COALESCE(expires_at, '9999-12-31T23:59:59.000Z') DESC, updated_at DESC
		 LIMIT 1`,
		userId,
		now,
		now,
	);
	return mapEntitlement(row);
}

async function getLatestEntitlementForUser(env: Env, userId: string) {
	await ensureEntitlementTables(env);
	const row = await queryFirst<EntitlementRow>(
		env.DB,
		`SELECT id, user_id, plan_tier, source, status, start_at, expires_at, auto_renew, external_product_id, external_original_transaction_id, last_validated_at, metadata_json, created_at, updated_at
		 FROM user_entitlements
		 WHERE user_id = ?
		 ORDER BY updated_at DESC
		 LIMIT 1`,
		userId,
	);
	return mapEntitlement(row);
}

async function getEffectiveEntitlementsByUserIds(env: Env, userIds: string[]) {
	await ensureEntitlementTables(env);
	const map = new Map<string, EntitlementRecord>();
	for (const userId of userIds) {
		const entitlement = await getEffectiveEntitlementForUser(env, userId);
		if (entitlement) map.set(userId, entitlement);
	}
	return map;
}

async function sha256Hex(input: string) {
	const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
	const bytes = new Uint8Array(digest);
	return [...bytes].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export function getClientIp(c: AppContext) {
	const cfIp = c.req.header("cf-connecting-ip");
	if (cfIp && cfIp.trim()) return cfIp.trim();
	const forwarded = c.req.header("x-forwarded-for");
	if (forwarded && forwarded.trim()) return forwarded.split(",")[0]?.trim() ?? null;
	return null;
}

export type RateLimitDecision = {
	limited: boolean;
	remaining: number;
	retryAfterSec: number;
	limit: number;
	windowSec: number;
};

export type SafetyEventType =
	| "prompt_limit_rejection"
	| "completion_limit_rejection"
	| "expensive_model_violation"
	| "kill_switch_triggered"
	| "daily_cost_cap_exhausted"
	| "rpm_limit_rejection"
	| "stream_concurrency_rejection"
	| "quota_exhaustion"
	| "stream_truncated"
	| "fal_budget_rejection"
	| "fal_global_circuit"
	| "fal_error";

export type SafetyEventInput = {
	type: SafetyEventType;
	userId?: string | null;
	ip?: string | null;
	requestId?: string | null;
	modelId?: string | null;
	planTier?: PlanTier | null;
	code: string;
	message: string;
	details?: Record<string, unknown> | null;
};

export type SlidingWindowRateLimitDecision = {
	limited: boolean;
	remaining: number;
	retryAfterSec: number;
	limit: number;
	windowSec: number;
};

export type HardPromptGuardDecision = {
	allowed: boolean;
	limit: number;
	estimatedPromptTokens: number;
	code?: string;
	message?: string;
};

export type ExpensiveModelDecision = {
	allowed: boolean;
	code?: string;
	message?: string;
	reason?: "not_expensive" | "kill_switch" | "allowlist_denied" | "allowlist_allowed";
};

export type CostReservationDecision = {
	reserved: boolean;
	requestId: string;
	limit: number;
	used: number;
	projected: number;
	code?: string;
	message?: string;
};

export async function consumeRateLimit(
	env: Env,
	input: { scope: string; identifier: string; limit: number; windowSec: number }
): Promise<RateLimitDecision> {
	await ensureSecurityTables(env);
	const now = Date.now();
	const windowMs = input.windowSec * 1000;
	const windowStartMs = Math.floor(now / windowMs) * windowMs;
	const identifierHash = await sha256Hex(`${input.scope}:${input.identifier}`);
	const bucketKey = `${input.scope}:${identifierHash}:${windowStartMs}`;
	const nowAt = nowIso();

	await exec(
		env.DB,
		`INSERT INTO rate_limits (bucket_key, scope, identifier_hash, window_start_ms, window_seconds, count, created_at, last_seen_at)
		 VALUES (?, ?, ?, ?, ?, 1, ?, ?)
		 ON CONFLICT(bucket_key) DO UPDATE SET count = count + 1, last_seen_at = excluded.last_seen_at`,
		bucketKey,
		input.scope,
		identifierHash,
		windowStartMs,
		input.windowSec,
		nowAt,
		nowAt,
	);

	const row = await queryFirst<{ count: number }>(env.DB, "SELECT count FROM rate_limits WHERE bucket_key = ? LIMIT 1", bucketKey);
	const count = Number(row?.count ?? 0);
	const retryAfterSec = Math.max(1, Math.ceil((windowStartMs + windowMs - now) / 1000));
	const remaining = Math.max(0, input.limit - count);

	if (Math.random() < 0.02) {
		const cutoff = now - 1000 * 60 * 60 * 24 * 2;
		void exec(env.DB, "DELETE FROM rate_limits WHERE window_start_ms < ?", cutoff);
	}

	return {
		limited: count > input.limit,
		remaining,
		retryAfterSec,
		limit: input.limit,
		windowSec: input.windowSec,
	};
}

export async function consumeSlidingWindowRateLimit(
	env: Env,
	input: { scope: string; identifier: string; limit: number; windowSec: number },
): Promise<SlidingWindowRateLimitDecision> {
	await ensureSecurityTables(env);
	const nowMs = Date.now();
	const windowStartMs = nowMs - input.windowSec * 1000;
	const identifierHash = await sha256Hex(`${input.scope}:${input.identifier}`);
	const eventId = randomId();
	const nowAt = nowIso();

	await exec(env.DB, "DELETE FROM rate_limit_events WHERE scope = ? AND identifier_hash = ? AND event_ms < ?", input.scope, identifierHash, windowStartMs);
	await exec(
		env.DB,
		"INSERT INTO rate_limit_events (id, scope, identifier_hash, event_ms, created_at) VALUES (?, ?, ?, ?, ?)",
		eventId,
		input.scope,
		identifierHash,
		nowMs,
		nowAt,
	);

	const countRow = await queryFirst<{ count: number }>(
		env.DB,
		"SELECT COUNT(*) AS count FROM rate_limit_events WHERE scope = ? AND identifier_hash = ? AND event_ms >= ?",
		input.scope,
		identifierHash,
		windowStartMs,
	);
	const firstEventRow = await queryFirst<{ firstMs: number }>(
		env.DB,
		"SELECT MIN(event_ms) AS firstMs FROM rate_limit_events WHERE scope = ? AND identifier_hash = ? AND event_ms >= ?",
		input.scope,
		identifierHash,
		windowStartMs,
	);
	const count = Number(countRow?.count ?? 0);
	const firstMs = Number(firstEventRow?.firstMs ?? nowMs);
	const retryAfterSec = Math.max(1, Math.ceil((firstMs + input.windowSec * 1000 - nowMs) / 1000));

	if (Math.random() < 0.02) {
		const cutoff = nowMs - 1000 * 60 * 60 * 24 * 2;
		void exec(env.DB, "DELETE FROM rate_limit_events WHERE event_ms < ?", cutoff);
	}

	return {
		limited: count > input.limit,
		remaining: Math.max(0, input.limit - count),
		retryAfterSec,
		limit: input.limit,
		windowSec: input.windowSec,
	};
}

export function applyRateLimitHeaders(c: AppContext, decision: RateLimitDecision) {
	c.header("Retry-After", String(decision.retryAfterSec));
	c.header("X-RateLimit-Limit", String(decision.limit));
	c.header("X-RateLimit-Remaining", String(decision.remaining));
	c.header("X-RateLimit-Window", String(decision.windowSec));
}

export type UsageEventInput = {
	userId: string | null;
	chatId: string | null;
	modelId: string | null;
	endpoint: string;
	inputMessageCount: number;
	inputChars: number;
	maxTokensRequested: number | null;
	outputChars: number;
	status: "completed" | "truncated" | "upstream_error" | "client_error";
	finishReason: string | null;
	ip: string | null;
};

type StreamLedgerStatus = "started" | "completed" | "truncated" | "upstream_error" | "client_error";

type StreamLedgerStartInput = {
	requestId: string;
	userId: string;
	modelId: string;
	endpoint: string;
	planTier: PlanTier;
	estimatedInputTokens: number;
	reservedOutputTokens: number;
	estimatedTotalTokens: number;
	estimatedCostUnits: number;
	status: StreamLedgerStatus;
};

type StreamLedgerFinalizeInput = {
	requestId: string;
	status: Exclude<StreamLedgerStatus, "started">;
	actualOutputChars: number;
};

export type RollingUsageDecision = {
	limited: boolean;
	code?: string;
	message?: string;
	requests: number;
	totalEstimatedTokens: number;
	totalEstimatedCostUnits: number;
};

export type GlobalSpendDecision = {
	limited: boolean;
	code?: string;
	message?: string;
	totalEstimatedCostUnits: number;
	limit: number;
};

export type StreamConcurrencyDecision = {
	limited: boolean;
	code?: string;
	message?: string;
	leaseId: string | null;
	active: number;
	limit: number;
};

// === USAGE LIMITS ===
// No burst window. Only 4-week rolling window.
// Free tier: unlimited (free models cost us nothing).
// Paid tiers: 4-week (28-day) rolling limit.

const PLAN_DAILY_TOKENS_DEFAULT: Record<PlanTier, number> = {
	free: 999999999,  // unlimited
	starter: 200000,
	pro: 500000,
	power: 500000,
};

// 4-week limits (28 days)
const PLAN_WEEKLY_TOKENS: Record<PlanTier, number> = {
	free: 999999999,   // unlimited
	starter: 4000000,  // ~200K/day * 28 with headroom
	pro: 10000000,     // ~500K/day * 28 with headroom
	power: 20000000,   // generous
};

const PLAN_DAILY_COST_UNITS_DEFAULT: Record<PlanTier, number> = {
	free: 999999999,   // unlimited
	starter: 15000,
	pro: 50000,
	power: 120000,
};

// 4-week limits (28 days)
const PLAN_WEEKLY_COST_UNITS: Record<PlanTier, number> = {
	free: 999999999,   // unlimited
	starter: 300000,
	pro: 1000000,
	power: 2400000,
};

const PLAN_REQUEST_TOKENS_DEFAULT: Record<PlanTier, number> = {
	free: 3072,
	starter: 6144,
	pro: 8192,
	power: 8192,
};

const PLAN_STREAM_CONCURRENCY_DEFAULT: Record<PlanTier, number> = {
	free: 1,
	starter: 2,
	pro: 3,
	power: 4,
};

export async function recordUsageEvent(env: Env, event: UsageEventInput) {
	await ensureSecurityTables(env);
	const ipHash = event.ip ? await sha256Hex(event.ip) : null;
	await exec(
		env.DB,
		`INSERT INTO usage_events
		 (id, user_id, chat_id, model_id, endpoint, input_message_count, input_chars, max_tokens_requested, output_chars, status, finish_reason, ip_hash, created_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		randomId(),
		event.userId,
		event.chatId,
		event.modelId,
		event.endpoint,
		event.inputMessageCount,
		event.inputChars,
		event.maxTokensRequested,
		event.outputChars,
		event.status,
		event.finishReason,
		ipHash,
		nowIso(),
	);
}

export async function recordSafetyEvent(env: Env, event: SafetyEventInput) {
	await ensureSecurityTables(env);
	const ipHash = event.ip ? await sha256Hex(event.ip) : null;
	await exec(
		env.DB,
		`INSERT INTO safety_events
		 (id, event_type, user_id, ip_hash, request_id, model_id, plan_tier, code, message, details_json, created_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		randomId(),
		event.type,
		event.userId ?? null,
		ipHash,
		event.requestId ?? null,
		event.modelId ?? null,
		event.planTier ?? null,
		event.code,
		event.message,
		event.details ? JSON.stringify(event.details) : null,
		nowIso(),
	);
}

export function hardPromptTokenLimit(env: Env) {
	return envInt(env, "TAI_HARD_PROMPT_TOKENS_MAX", 24000, 256, 1000000);
}

export function hardCompletionTokenLimit(env: Env) {
	return envInt(env, "TAI_HARD_COMPLETION_TOKENS_MAX", 4096, 64, 65536);
}

export function applyHardPromptGuard(env: Env, estimatedPromptTokens: number): HardPromptGuardDecision {
	const limit = hardPromptTokenLimit(env);
	if (estimatedPromptTokens <= limit) {
		return {
			allowed: true,
			limit,
			estimatedPromptTokens,
		};
	}
	return {
		allowed: false,
		limit,
		estimatedPromptTokens,
		code: "HARD_PROMPT_TOKEN_LIMIT",
		message: "Prompt exceeds absolute token safety limit.",
	};
}

function expensiveModelCategoriesSet() {
	return new Set<ModelCategory>(["premium-reasoning", "premium-creative", "image-generation"]);
}

function isExpensiveModel(model: Pick<ModelRecord, "category" | "providerModelId" | "id">, env: Env) {
	const explicitList = envString(env, "TAI_EXPENSIVE_MODEL_IDS")
		.split(",")
		.map((entry) => entry.trim())
		.filter(Boolean);
	if (explicitList.length > 0) {
		return explicitList.includes(model.providerModelId) || explicitList.includes(model.id);
	}
	return model.category ? expensiveModelCategoriesSet().has(model.category) : false;
}

function parseExpensiveModelAllowlist(env: Env): Record<string, PlanTier[]> {
	const raw = envString(env, "TAI_EXPENSIVE_MODEL_ALLOWLIST_JSON").trim();
	if (!raw) return {};
	try {
		const parsed = JSON.parse(raw) as Record<string, unknown>;
		const out: Record<string, PlanTier[]> = {};
		for (const [modelKey, value] of Object.entries(parsed)) {
			if (!Array.isArray(value)) continue;
			const tiers = value
				.map((entry) => String(entry).trim().toLowerCase())
				.filter((entry): entry is PlanTier => entry === "free" || entry === "starter" || entry === "pro" || entry === "power");
			if (tiers.length) out[modelKey] = tiers;
		}
		return out;
	} catch {
		return {};
	}
}

export function enforceExpensiveModelAccess(
	env: Env,
	input: { planTier: PlanTier; model: Pick<ModelRecord, "id" | "providerModelId" | "category"> },
): ExpensiveModelDecision {
	const { planTier, model } = input;
	if (!isExpensiveModel(model, env)) {
		return { allowed: true, reason: "not_expensive" };
	}

	const killSwitchEnabled = envBool(env, "TAI_EXPENSIVE_MODELS_KILL_SWITCH", false);
	if (killSwitchEnabled) {
		return {
			allowed: false,
			reason: "kill_switch",
			code: "DEGRADED_MODE_EXPENSIVE_MODELS_DISABLED",
			message: "Expensive models are temporarily disabled while degraded mode is active.",
		};
	}

	const allowlist = parseExpensiveModelAllowlist(env);
	const allowlistEntry = allowlist[model.providerModelId] ?? allowlist[model.id] ?? null;
	if (!allowlistEntry) {
		return { allowed: true, reason: "allowlist_allowed" };
	}
	if (allowlistEntry.includes(planTier)) {
		return { allowed: true, reason: "allowlist_allowed" };
	}
	return {
		allowed: false,
		reason: "allowlist_denied",
		code: "UPGRADE_REQUIRED_EXPENSIVE_MODEL",
		message: "This model requires a higher plan tier.",
	};
}

export async function reserveDailyCostLedgerStart(
	env: Env,
	input: {
		requestId: string;
		userId: string;
		modelId: string;
		endpoint: string;
		planTier: PlanTier;
		estimatedInputTokens: number;
		reservedOutputTokens: number;
		estimatedTotalTokens: number;
		estimatedCostUnits: number;
	},
): Promise<CostReservationDecision> {
	await ensureSecurityTables(env);
	const now = nowIso();
	const dayStart = new Date();
	dayStart.setUTCHours(0, 0, 0, 0);
	const dayStartIso = dayStart.toISOString();
	const limit = planDailyCostUnitsLimit(env, input.planTier);

	const insertResult = await exec(
		env.DB,
		`INSERT INTO usage_ledger
		 (request_id, user_id, model_id, endpoint, plan_tier, estimated_input_tokens, reserved_output_tokens, estimated_total_tokens, estimated_cost_units, actual_output_chars, status, created_at, updated_at)
		 SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'started', ?, ?
		 WHERE (
		 	COALESCE((
		 		SELECT SUM(estimated_cost_units)
		 		FROM usage_ledger
		 		WHERE user_id = ?
		 		  AND created_at >= ?
		 		  AND status IN ('started', 'completed', 'truncated', 'upstream_error', 'client_error')
		 	), 0) + ?
		 ) <= ?`,
		input.requestId,
		input.userId,
		input.modelId,
		input.endpoint,
		input.planTier,
		input.estimatedInputTokens,
		input.reservedOutputTokens,
		input.estimatedTotalTokens,
		input.estimatedCostUnits,
		now,
		now,
		input.userId,
		dayStartIso,
		input.estimatedCostUnits,
		limit,
	);

	const changes = Number(insertResult.meta?.changes ?? 0);
	const row = await queryFirst<{ totalCostUnits: number }>(
		env.DB,
		`SELECT COALESCE(SUM(estimated_cost_units), 0) AS totalCostUnits
		 FROM usage_ledger
		 WHERE user_id = ?
		   AND created_at >= ?
		   AND status IN ('started', 'completed', 'truncated', 'upstream_error', 'client_error')`,
		input.userId,
		dayStartIso,
	);
	const used = Number(row?.totalCostUnits ?? 0);
	if (changes < 1) {
		return {
			reserved: false,
			requestId: input.requestId,
			limit,
			used,
			projected: used + input.estimatedCostUnits,
			code: "DAILY_HARD_COST_CAP",
			message: "Daily hard cost cap reached for this account.",
		};
	}

	return {
		reserved: true,
		requestId: input.requestId,
		limit,
		used,
		projected: used,
	};
}

export async function recordStreamLedgerRejection(
	env: Env,
	input: {
		requestId: string;
		userId: string;
		modelId: string;
		endpoint: string;
		planTier: PlanTier;
		estimatedInputTokens: number;
		reservedOutputTokens: number;
		estimatedTotalTokens: number;
		estimatedCostUnits: number;
		status: string;
	},
) {
	await ensureSecurityTables(env);
	const now = nowIso();
	await exec(
		env.DB,
		`INSERT OR REPLACE INTO usage_ledger
		 (request_id, user_id, model_id, endpoint, plan_tier, estimated_input_tokens, reserved_output_tokens, estimated_total_tokens, estimated_cost_units, actual_output_chars, status, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)`,
		input.requestId,
		input.userId,
		input.modelId,
		input.endpoint,
		input.planTier,
		input.estimatedInputTokens,
		input.reservedOutputTokens,
		input.estimatedTotalTokens,
		input.estimatedCostUnits,
		input.status,
		now,
		now,
	);
}

export async function checkStreamQuota(env: Env, userId: string) {
	await ensureSecurityTables(env);
	const dailyRequestLimit = envInt(env, "TAI_DAILY_STREAM_REQUEST_LIMIT", 200, 1, 10000);
	const dailyOutputCharLimit = envInt(env, "TAI_DAILY_STREAM_OUTPUT_CHAR_LIMIT", 500000, 1000, 100000000);
	const dayStart = new Date();
	dayStart.setUTCHours(0, 0, 0, 0);
	const dayStartIso = dayStart.toISOString();
	const usage = await queryFirst<{ requests: number; outputChars: number }>(
		env.DB,
		`SELECT COUNT(*) AS requests, COALESCE(SUM(output_chars), 0) AS outputChars
		 FROM usage_events
		 WHERE user_id = ?
		   AND endpoint = '/api/chat/stream'
		   AND created_at >= ?`,
		userId,
		dayStartIso,
	);
	const requests = Number(usage?.requests ?? 0);
	const outputChars = Number(usage?.outputChars ?? 0);
	if (requests >= dailyRequestLimit) {
		return {
			limited: true,
			code: "DAILY_STREAM_REQUEST_LIMIT",
			message: "Daily stream request limit reached.",
			requests,
			outputChars,
		};
	}
	if (outputChars >= dailyOutputCharLimit) {
		return {
			limited: true,
			code: "DAILY_STREAM_OUTPUT_LIMIT",
			message: "Daily stream output quota reached.",
			requests,
			outputChars,
		};
	}
	return { limited: false, requests, outputChars };
}

type AuthTokenType = "email_verification" | "password_reset";

type AuthTokenRow = {
	id: string;
	type: AuthTokenType;
	user_id: string | null;
	email: string | null;
	token_hash: string;
	expires_at: string;
	used_at: string | null;
	created_at: string;
};

function randomTokenValue() {
	const bytes = crypto.getRandomValues(new Uint8Array(32));
	return base64UrlEncode(bytes);
}

type IssueAuthTokenInput = {
	type: AuthTokenType;
	userId: string;
	email: string;
	ttlSec: number;
};

type IssueAuthTokenResult = {
	token: string;
	expiresAt: string;
};

type EmailDeliveryResult = {
	attempted: boolean;
	sent: boolean;
	provider: "resend" | null;
};

function resolvePublicOrigin(env: Env) {
	const configured = envString(env, "TAI_PUBLIC_ORIGIN").trim();
	if (!configured) return "https://ai.gravitilabs.com";
	try {
		const url = new URL(configured);
		if (url.protocol !== "https:") return "https://ai.gravitilabs.com";
		return `${url.origin}`.replace(/\/+$/, "");
	} catch {
		return "https://ai.gravitilabs.com";
	}
}

function authActionLink(env: Env, action: "verify" | "reset", token: string, email: string) {
	const origin = resolvePublicOrigin(env);
	const url = new URL(origin);
	url.searchParams.set("auth", action);
	url.searchParams.set("token", token);
	url.searchParams.set("email", email);
	return url.toString();
}

async function sendEmailViaResend(
	env: Env,
	input: { to: string; subject: string; html: string; text: string },
): Promise<EmailDeliveryResult> {
	const apiKey = envString(env, "RESEND_API_KEY").trim();
	const from = envString(env, "TAI_EMAIL_FROM").trim();
	if (!apiKey || !from) {
		console.warn("[auth-email] resend disabled: missing RESEND_API_KEY or TAI_EMAIL_FROM");
		return { attempted: false, sent: false, provider: "resend" };
	}

	const replyTo = envString(env, "TAI_EMAIL_REPLY_TO").trim();
	try {
		const response = await fetch("https://api.resend.com/emails", {
			method: "POST",
			headers: {
				Authorization: `Bearer ${apiKey}`,
				"Content-Type": "application/json",
			},
			body: JSON.stringify({
				from,
				to: [input.to],
				subject: input.subject,
				html: input.html,
				text: input.text,
				...(replyTo ? { reply_to: replyTo } : {}),
			}),
		});

		if (!response.ok) {
			const detail = (await response.text()).slice(0, 400);
			console.error(`[auth-email] resend failure (${response.status}): ${detail}`);
			return { attempted: true, sent: false, provider: "resend" };
		}
	} catch (error) {
		console.error("[auth-email] resend request error", error);
		return { attempted: true, sent: false, provider: "resend" };
	}

	return { attempted: true, sent: true, provider: "resend" };
}

function emailBaseTemplate(options: {
	heading: string;
	bodyHtml: string;
	ctaText?: string;
	ctaUrl?: string;
	footerNote?: string;
}): string {
	const fontStack = "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif";
	const cta = options.ctaText && options.ctaUrl ? `
		<tr><td align="center" style="padding: 32px 0;">
			<!--[if mso]><v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="${options.ctaUrl}" style="height:48px;v-text-anchor:middle;width:240px;" arcsize="50%" strokecolor="#0071e3" fillcolor="#0071e3"><w:anchorlock/><center style="color:#ffffff;font-family:${fontStack};font-size:16px;font-weight:600;">
			${options.ctaText}</center></v:roundrect><![endif]-->
			<!--[if !mso]><!-->
			<a href="${options.ctaUrl}" target="_blank" style="display:inline-block;background-color:#0071e3;color:#ffffff;font-family:${fontStack};font-size:16px;font-weight:600;text-decoration:none;padding:14px 44px;border-radius:980px;mso-hide:all;">${options.ctaText}</a>
			<!--<![endif]-->
		</td></tr>
		<tr><td align="center" style="padding: 0 0 8px; font-family: ${fontStack}; font-size: 12px; color: #86868b; line-height: 1.5;">
			If the button doesn't work, copy and paste this link into your browser:
		</td></tr>
		<tr><td align="center" style="padding: 0 0 24px; font-family: ${fontStack}; font-size: 12px; color: #86868b; line-height: 1.5; word-break: break-all;">
			<a href="${options.ctaUrl}" style="color: #86868b; text-decoration: underline;">${options.ctaUrl}</a>
		</td></tr>` : "";

	const footerNote = options.footerNote ? `
		<tr><td align="center" style="padding: 24px 0 0; font-family: ${fontStack}; font-size: 13px; color: #86868b; line-height: 1.5;">
			${options.footerNote}
		</td></tr>` : "";

	return `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="x-apple-disable-message-reformatting"><meta name="format-detection" content="telephone=no,address=no,email=no,date=no,url=no"><title>${options.heading}</title>
<style>@media only screen and (max-width:600px){.email-card{padding:32px 24px !important}.email-cta{width:100% !important;max-width:340px !important}}</style>
<!--[if mso]><noscript><xml><o:OfficeDocumentSettings><o:AllowPNG/><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml></noscript><![endif]-->
</head><body style="margin:0;padding:0;background-color:#f5f5f7;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;">
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color:#f5f5f7;">
<tr><td align="center" style="padding:40px 16px;">
	<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="600" style="max-width:600px;width:100%;">
	<tr><td class="email-card" style="background-color:#ffffff;border-radius:12px;padding:48px 40px;box-shadow:0 1px 3px rgba(0,0,0,0.08);">
		<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
		<!-- Header -->
		<tr><td align="center" style="padding:0 0 20px;font-family:${fontStack};font-size:28px;font-weight:700;letter-spacing:6px;color:#1d1d1f;">TABAI</td></tr>
		<tr><td align="center" style="padding:0 0 20px;"><div style="width:40px;height:1px;background-color:#d2d2d7;margin:0 auto;"></div></td></tr>
		<!-- Heading -->
		<tr><td align="center" style="padding:0 0 24px;font-family:${fontStack};font-size:24px;font-weight:600;color:#1d1d1f;line-height:1.25;">${options.heading}</td></tr>
		<!-- Body -->
		<tr><td align="center" style="font-family:${fontStack};font-size:16px;font-weight:400;color:#424245;line-height:1.625;">${options.bodyHtml}</td></tr>
		<!-- CTA -->
		${cta}
		<!-- Footer note -->
		${footerNote}
		</table>
	</td></tr>
	<!-- Footer -->
	<tr><td align="center" style="padding:32px 0 24px;">
		<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
		<tr><td align="center" style="font-family:${fontStack};font-size:12px;color:#86868b;line-height:1.5;">TABA TASARIM INSAAT A.S.</td></tr>
		<tr><td align="center" style="font-family:${fontStack};font-size:12px;color:#86868b;line-height:1.5;">Sehit Sakir Elkovan cad. No:3 Atasehir Istanbul Turkiye</td></tr>
		<tr><td align="center" style="padding:4px 0 0;font-family:${fontStack};font-size:12px;line-height:1.5;"><a href="https://ai.gravitilabs.com" style="color:#86868b;text-decoration:none;">ai.gravitilabs.com</a></td></tr>
		</table>
	</td></tr>
	</table>
</td></tr>
</table>
</body></html>`;
}

function stripHtml(html: string): string {
	return html.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
}

async function sendVerificationEmail(env: Env, email: string, token: string, expiresAt: string) {
	const link = authActionLink(env, "verify", token, email);
	const html = emailBaseTemplate({
		heading: "Verify your email.",
		bodyHtml: "To start using TABAI, confirm this is your email address by clicking the button below.",
		ctaText: "Verify Email Address",
		ctaUrl: link,
		footerNote: "This link will expire in 24 hours. If you didn't create a TABAI account, you can safely ignore this email.",
	});
	return sendEmailViaResend(env, {
		to: email,
		subject: "Verify your email address",
		html,
		text: `Verify your email.\n\nTo start using TABAI, confirm this is your email address by opening the link below:\n\n${link}\n\nThis link will expire in 24 hours. If you didn't create a TABAI account, you can safely ignore this email.`,
	});
}

export async function sendWelcomeEmail(env: Env, email: string, displayName?: string | null): Promise<{ attempted: boolean; sent: boolean }> {
	const html = emailBaseTemplate({
		heading: "You're all set.",
		bodyHtml: `<p style="margin:0 0 20px;">Your email has been verified and your TABAI account is ready to use.</p>
<p style="margin:0 0 20px;">TABAI brings the world's most powerful AI models together in one place &mdash; GPT-4o, Claude, Gemini, Llama, and more. Ask anything, and TABAI's Smart Model will automatically choose the best AI for your question.</p>
<p style="margin:0;">When you're ready for more, upgrade your plan to unlock premium models, image generation, and video creation.</p>`,
		ctaText: "Open TABAI",
		ctaUrl: "https://ai.gravitilabs.com",
		footerNote: "If you have any questions, simply reply to this email.",
	});
	const result = await sendEmailViaResend(env, {
		to: email,
		subject: "Welcome to TABAI",
		html,
		text: `You're all set.\n\nYour email has been verified and your TABAI account is ready to use.\n\nTABAI brings the world's most powerful AI models together in one place — GPT-4o, Claude, Gemini, Llama, and more. Ask anything, and TABAI's Smart Model will automatically choose the best AI for your question.\n\nWhen you're ready for more, upgrade your plan to unlock premium models, image generation, and video creation.\n\nOpen TABAI: https://ai.gravitilabs.com`,
	});
	return { attempted: result.attempted, sent: result.sent };
}

async function sendPasswordResetEmail(env: Env, email: string, token: string, expiresAt: string) {
	const link = authActionLink(env, "reset", token, email);
	const html = emailBaseTemplate({
		heading: "Reset your password.",
		bodyHtml: "We received a request to reset the password for the TABAI account associated with this email address. Click the button below to set a new password.",
		ctaText: "Reset Password",
		ctaUrl: link,
		footerNote: "This link will expire in 1 hour. If you didn't request a password reset, no action is needed &mdash; your account is secure.",
	});
	return sendEmailViaResend(env, {
		to: email,
		subject: "Reset your password",
		html,
		text: `Reset your password.\n\nWe received a request to reset the password for the TABAI account associated with this email address. Use the link below to set a new password:\n\n${link}\n\nThis link will expire in 1 hour. If you didn't request a password reset, no action is needed — your account is secure.`,
	});
}

async function issueAuthToken(env: Env, input: IssueAuthTokenInput): Promise<IssueAuthTokenResult> {
	await ensureSecurityTables(env);
	const token = randomTokenValue();
	const tokenHash = await sha256Hex(token);
	const nowAt = nowIso();
	const expiresAt = new Date(Date.now() + input.ttlSec * 1000).toISOString();
	await exec(
		env.DB,
		"UPDATE auth_tokens SET used_at = ? WHERE type = ? AND user_id = ? AND used_at IS NULL",
		nowAt,
		input.type,
		input.userId,
	);
	await exec(
		env.DB,
		"INSERT INTO auth_tokens (id, type, user_id, email, token_hash, expires_at, used_at, created_at) VALUES (?, ?, ?, ?, ?, ?, NULL, ?)",
		randomId(),
		input.type,
		input.userId,
		input.email.toLowerCase(),
		tokenHash,
		expiresAt,
		nowAt,
	);
	return { token, expiresAt };
}

async function consumeAuthToken(env: Env, type: AuthTokenType, token: string) {
	await ensureSecurityTables(env);
	const tokenHash = await sha256Hex(token);
	const row = await queryFirst<AuthTokenRow>(
		env.DB,
		"SELECT id, type, user_id, email, token_hash, expires_at, used_at, created_at FROM auth_tokens WHERE type = ? AND token_hash = ? LIMIT 1",
		type,
		tokenHash,
	);
	if (!row) return { ok: false as const, reason: "TOKEN_INVALID" as const };
	if (row.used_at) return { ok: false as const, reason: "TOKEN_USED" as const };
	if (Date.parse(row.expires_at) <= Date.now()) return { ok: false as const, reason: "TOKEN_EXPIRED" as const };
	await exec(env.DB, "UPDATE auth_tokens SET used_at = ? WHERE id = ? AND used_at IS NULL", nowIso(), row.id);
	return { ok: true as const, row };
}

function maybeExposeToken(env: Env, token: string | null) {
	if (!token) return null;
	return envBool(env, "TAI_AUTH_EXPOSE_TOKENS", false) ? token : null;
}

function usernameFromEmail(email: string) {
	const local = email.split("@")[0] || "user";
	return local.toLowerCase().replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 70) || "user";
}

async function resolveUniqueUsername(env: Env, requested: string) {
	const base = requested.toLowerCase().replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 70) || "user";
	for (let i = 0; i < 100; i += 1) {
		const candidate = i === 0 ? base : `${base}-${i + 1}`;
		const exists = await queryFirst<{ id: string }>(env.DB, "SELECT id FROM users WHERE lower(username) = lower(?) LIMIT 1", candidate);
		if (!exists) return candidate;
	}
	return `${base}-${Math.floor(Math.random() * 100000)}`;
}

export async function signupUser(env: Env, input: z.infer<typeof signupSchema>) {
	await ensureSecurityTables(env);
	// Password strength validation
	const pw = input.password;
	if (pw.length < 8) return { ok: false as const, code: "WEAK_PASSWORD" as const, error: "Password must be at least 8 characters." };
	if (!/[A-Z]/.test(pw)) return { ok: false as const, code: "WEAK_PASSWORD" as const, error: "Password must contain an uppercase letter." };
	if (!/[a-z]/.test(pw)) return { ok: false as const, code: "WEAK_PASSWORD" as const, error: "Password must contain a lowercase letter." };
	if (!/\d/.test(pw)) return { ok: false as const, code: "WEAK_PASSWORD" as const, error: "Password must contain a number." };
	if (!/[!@#$%^&*()_+\-=\[\]{}|;:'",.<>?/~`]/.test(pw)) return { ok: false as const, code: "WEAK_PASSWORD" as const, error: "Password must contain a special character." };
	const email = input.email.trim().toLowerCase();
	const existing = await queryFirst<{ id: string }>(env.DB, "SELECT id FROM users WHERE lower(email) = lower(?) LIMIT 1", email);
	if (existing) {
		return { ok: false as const, code: "EMAIL_EXISTS" as const, error: "An account already exists for this email." };
	}
	const createdAt = nowIso();
	const id = randomId();
	const username = await resolveUniqueUsername(env, input.username?.trim() || usernameFromEmail(email));
	await exec(
		env.DB,
		"INSERT INTO users (id, email, username, display_name, password_hash, role, status, plan_tier, email_verified_at, session_version, last_active_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 'USER', 'ENABLED', 'FREE', NULL, 0, NULL, ?, ?)",
		id,
		email,
		username,
		input.displayName?.trim() || null,
		await hashPassword(input.password),
		createdAt,
		createdAt,
	);
	await exec(
		env.DB,
		"INSERT INTO user_settings (user_id, theme, language, notifications_enabled, voice_session_enabled, updated_at) VALUES (?, 'system', 'en', 1, 0, ?)",
		id,
		createdAt,
	);
	const verification = await issueAuthToken(env, {
		type: "email_verification",
		userId: id,
		email,
		ttlSec: envInt(env, "TAI_EMAIL_VERIFICATION_TTL_SEC", 60 * 60 * 24, 300, 60 * 60 * 24 * 7),
	});
	const emailDelivery = await sendVerificationEmail(env, email, verification.token, verification.expiresAt);
	return {
		ok: true as const,
		user: await getUserById(env, id),
		verificationRequired: true,
		verificationTokenIssued: true,
		verificationEmailSent: emailDelivery.sent,
		emailProvider: emailDelivery.provider,
		verificationToken: maybeExposeToken(env, verification.token),
		verificationTokenExpiresAt: verification.expiresAt,
	};
}

export async function findOrCreateAppleUser(env: Env, email: string | null, appleUserId: string, displayName: string | null) {
	await ensureSecurityTables(env);

	// Step 1: Look up by apple_user_id (provider subject ID) FIRST
	const byProviderId = await queryFirst<UserRow>(
		env.DB,
		"SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE apple_user_id = ? LIMIT 1",
		appleUserId,
	);
	if (byProviderId) {
		// Update apple_user_id in case it wasn't set before
		const user = await getUserById(env, byProviderId.id);
		return { user, created: false };
	}

	// Step 2: Fall back to email lookup (for existing users who signed up before apple_user_id column)
	if (email) {
		const normalizedEmail = email.trim().toLowerCase();
		const existing = await queryFirst<UserRow>(
			env.DB,
			"SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE lower(email) = lower(?) LIMIT 1",
			normalizedEmail,
		);
		if (existing) {
			// Link apple_user_id to existing account for future lookups
			await exec(env.DB, "UPDATE users SET apple_user_id = ?, updated_at = ? WHERE id = ?", appleUserId, nowIso(), existing.id);
			const user = await getUserById(env, existing.id);
			return { user, created: false };
		}
	}

	// Step 3: New user — email is required for first sign-up
	if (!email) {
		return { user: null, created: false };
	}

	const normalizedEmail = email.trim().toLowerCase();
	const id = randomId();
	const createdAt = nowIso();
	const username = await resolveUniqueUsername(env, displayName?.replace(/\s+/g, "").toLowerCase() || usernameFromEmail(normalizedEmail));
	const placeholderHash = await hashPassword(randomId() + randomId());
	await exec(
		env.DB,
		"INSERT INTO users (id, email, username, display_name, password_hash, role, status, plan_tier, email_verified_at, apple_user_id, session_version, last_active_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 'USER', 'ENABLED', 'FREE', ?, ?, 0, NULL, ?, ?)",
		id,
		normalizedEmail,
		username,
		displayName,
		placeholderHash,
		createdAt, // email_verified_at — SSO emails are pre-verified
		appleUserId,
		createdAt,
		createdAt,
	);
	await exec(
		env.DB,
		"INSERT INTO user_settings (user_id, theme, language, notifications_enabled, voice_session_enabled, updated_at) VALUES (?, 'system', 'en', 1, 0, ?)",
		id,
		createdAt,
	);
	const user = await getUserById(env, id);
	return { user, created: true };
}

export async function requestEmailVerification(env: Env, emailRaw: string) {
	await ensureSecurityTables(env);
	const email = emailRaw.trim().toLowerCase();
	const row = await queryFirst<UserRow>(
		env.DB,
		"SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE lower(email) = lower(?) LIMIT 1",
		email,
	);
	if (!row || row.status !== "ENABLED" || row.email_verified_at) {
		return {
			ok: true as const,
			issued: false as const,
			verificationEmailSent: false,
			emailProvider: "resend" as const,
			verificationToken: null as string | null,
			verificationTokenExpiresAt: null as string | null,
		};
	}
	const verification = await issueAuthToken(env, {
		type: "email_verification",
		userId: row.id,
		email,
		ttlSec: envInt(env, "TAI_EMAIL_VERIFICATION_TTL_SEC", 60 * 60 * 24, 300, 60 * 60 * 24 * 7),
	});
	const emailDelivery = await sendVerificationEmail(env, email, verification.token, verification.expiresAt);
	return {
		ok: true as const,
		issued: true as const,
		verificationEmailSent: emailDelivery.sent,
		emailProvider: emailDelivery.provider,
		verificationToken: maybeExposeToken(env, verification.token),
		verificationTokenExpiresAt: verification.expiresAt,
	};
}

export async function confirmEmailVerification(env: Env, token: string) {
	const consumed = await consumeAuthToken(env, "email_verification", token);
	if (!consumed.ok) {
		return { ok: false as const, code: consumed.reason };
	}
	if (!consumed.row.user_id) {
		return { ok: false as const, code: "TOKEN_INVALID" as const };
	}
	await exec(
		env.DB,
		"UPDATE users SET email_verified_at = COALESCE(email_verified_at, ?), updated_at = ? WHERE id = ?",
		nowIso(),
		nowIso(),
		consumed.row.user_id,
	);
	const user = await getUserById(env, consumed.row.user_id);
	// Send welcome email after successful verification
	if (user) {
		sendWelcomeEmail(env, user.email, user.displayName).catch((err) =>
			console.error("[auth-email] welcome email error", err),
		);
	}
	return { ok: true as const, user };
}

export async function requestPasswordReset(env: Env, emailRaw: string) {
	await ensureSecurityTables(env);
	const email = emailRaw.trim().toLowerCase();
	const row = await queryFirst<UserRow>(
		env.DB,
		"SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE lower(email) = lower(?) LIMIT 1",
		email,
	);
	if (!row || row.status !== "ENABLED") {
		return {
			ok: true as const,
			issued: false as const,
			resetEmailSent: false,
			emailProvider: "resend" as const,
			resetToken: null as string | null,
			resetTokenExpiresAt: null as string | null,
		};
	}
	const reset = await issueAuthToken(env, {
		type: "password_reset",
		userId: row.id,
		email,
		ttlSec: envInt(env, "TAI_PASSWORD_RESET_TTL_SEC", 60 * 60, 300, 60 * 60 * 24),
	});
	const emailDelivery = await sendPasswordResetEmail(env, email, reset.token, reset.expiresAt);
	return {
		ok: true as const,
		issued: true as const,
		resetEmailSent: emailDelivery.sent,
		emailProvider: emailDelivery.provider,
		resetToken: maybeExposeToken(env, reset.token),
		resetTokenExpiresAt: reset.expiresAt,
	};
}

export async function confirmPasswordReset(env: Env, token: string, newPassword: string) {
	const consumed = await consumeAuthToken(env, "password_reset", token);
	if (!consumed.ok) {
		return { ok: false as const, code: consumed.reason };
	}
	if (!consumed.row.user_id) {
		return { ok: false as const, code: "TOKEN_INVALID" as const };
	}
	await exec(
		env.DB,
		"UPDATE users SET password_hash = ?, session_version = session_version + 1, last_active_at = NULL, updated_at = ? WHERE id = ?",
		await hashPassword(newPassword),
		nowIso(),
		consumed.row.user_id,
	);
	const user = await getUserById(env, consumed.row.user_id);
	return { ok: true as const, user };
}

type UserRow = {
	id: string;
	email: string;
	username: string;
	display_name: string | null;
	role: Role;
	status: UserStatus;
	plan_tier: PlanTier | null;
	password_hash: string;
	email_verified_at: string | null;
	session_version: number;
	last_active_at: string | null;
	created_at: string;
	updated_at: string;
	apple_user_id?: string | null;
};

type EntitlementRow = {
	id: string;
	user_id: string;
	plan_tier: PlanTier | null;
	source: EntitlementSource | null;
	status: EntitlementStatus | null;
	start_at: string;
	expires_at: string | null;
	auto_renew: number;
	external_product_id: string | null;
	external_original_transaction_id: string | null;
	last_validated_at: string | null;
	metadata_json: string | null;
	created_at: string;
	updated_at: string;
};

type FolderRow = {
	id: string;
	user_id: string;
	name: string;
	color: string | null;
	created_at: string;
	updated_at: string;
};

type ChatRow = {
	id: string;
	user_id: string;
	folder_id: string | null;
	title: string;
	model_id: string | null;
	is_pinned: number;
	is_deleted: number;
	created_at: string;
	updated_at: string;
};

type MessageRow = {
	id: string;
	chat_id: string;
	role: string;
	content: string;
	sequence: number;
	is_deleted: number;
	created_at: string;
	updated_at: string;
};

type ModelRow = {
	id: string;
	provider_model_id: string;
	name: string;
	vendor: string | null;
	logo: string | null;
	description: string | null;
	capabilities_json: string;
	context_length: number | null;
	pricing_tier: "free" | "paid" | null;
	is_enabled: number;
	verified: number;
	created_at: string;
	updated_at: string;
};

function mapUser(
	row: Pick<UserRow, "id" | "email" | "username" | "display_name" | "role" | "status" | "email_verified_at" | "plan_tier" | "last_active_at" | "created_at">,
	entitlement: EntitlementRecord | null = null,
): UserProfile {
	const storedPlanTier = normalizePlanTier(row.plan_tier);
	const effectivePlanTier = row.role === "ADMIN" ? storedPlanTier : entitlement?.planTier ?? "free";
	return {
		id: row.id,
		email: row.email,
		username: row.username,
		displayName: row.display_name,
		role: row.role,
		status: row.status,
		planTier: effectivePlanTier,
		emailVerified: !!row.email_verified_at,
		verificationRequired: !row.email_verified_at,
		entitlement,
		lastActiveAt: row.last_active_at ?? null,
		createdAt: row.created_at ?? null,
	};
}

function modelVendor(providerModelId: string) {
	const normalized = providerModelId.toLowerCase();
	if (normalized.startsWith("openai/")) return "openai";
	if (normalized.startsWith("anthropic/")) return "anthropic";
	if (normalized.startsWith("google/")) return "google";
	if (normalized.startsWith("meta-llama/")) return "meta";
	if (normalized.startsWith("mistralai/")) return "mistral";
	if (normalized.startsWith("deepseek/")) return "deepseek";
	if (normalized.startsWith("qwen/")) return "qwen";
	if (normalized.startsWith("x-ai/") || normalized.startsWith("xai/")) return "xai";
	if (normalized.startsWith("perplexity/")) return "perplexity";
	if (normalized.startsWith("nvidia/")) return "nvidia";
	if (normalized.startsWith("openrouter/")) return "openrouter";
	return "default";
}

function modelLogo(vendor: string) {
	return `/tai-icons/${vendor}.svg`;
}

function vendorLabel(vendor: string) {
	switch (vendor) {
		case "openai": return "OpenAI";
		case "anthropic": return "Anthropic";
		case "google": return "Google";
		case "meta": return "Meta";
		case "mistral": return "Mistral";
		case "deepseek": return "DeepSeek";
		case "qwen": return "Qwen";
		case "xai": return "xAI";
		case "perplexity": return "Perplexity";
		case "nvidia": return "Nvidia";
		case "openrouter": return "OpenRouter";
		default: return "AI";
	}
}

function prettifyToken(token: string) {
	const normalized = token.trim();
	if (!normalized) return "";
	const lower = normalized.toLowerCase();
	const exact: Record<string, string> = {
		ai: "AI",
		ai21: "AI21",
		api: "API",
		auto: "Auto",
		chat: "Chat",
		claude: "Claude",
		coder: "Coder",
		command: "Command",
		deepseek: "DeepSeek",
		embed: "Embed",
		embedding: "Embedding",
		flash: "Flash",
		free: "Free",
		gemma: "Gemma",
		gemini: "Gemini",
		gpt: "GPT",
		grok: "Grok",
		haiku: "Haiku",
		instruct: "Instruct",
		jamba: "Jamba",
		llama: "Llama",
		mini: "mini",
		mistral: "Mistral",
		nano: "nano",
		nemotron: "Nemotron",
		openrouter: "OpenRouter",
		pixtral: "Pixtral",
		pro: "Pro",
		qwen: "Qwen",
		reasoner: "Reasoner",
		router: "Router",
		sonnet: "Sonnet",
		turbo: "Turbo",
		ultra: "Ultra",
		vision: "Vision",
	};
	if (exact[lower]) return exact[lower];
	if (/^\d+(?:\.\d+)?[a-z]*$/i.test(normalized)) return normalized.toUpperCase() === normalized ? normalized : normalized;
	if (/^\d+b$/i.test(normalized)) return normalized.toUpperCase();
	if (/^[a-z]{1,3}\d.*$/i.test(normalized)) return normalized.toUpperCase();
	return normalized.charAt(0).toUpperCase() + normalized.slice(1);
}

function prettifyModelTail(tail: string) {
	let value = tail.trim().replace(/:free$/i, "").replace(/\(free\)/gi, "").trim();
	if (!value) return "AI Model";
	if (value === "auto") return "Auto Router";

	value = value
		.replace(/^gpt-/i, "GPT-")
		.replace(/^claude-/i, "Claude ")
		.replace(/^gemini-/i, "Gemini ")
		.replace(/^gemma-/i, "Gemma ")
		.replace(/^llama-/i, "Llama ")
		.replace(/^deepseek-/i, "DeepSeek ")
		.replace(/^qwen-/i, "Qwen ")
		.replace(/^grok-/i, "Grok ")
		.replace(/^pixtral-/i, "Pixtral ");

	const tokens = value
		.replace(/[/:_]+/g, " ")
		.replace(/-/g, " ")
		.replace(/\s+/g, " ")
		.trim()
		.split(" ")
		.filter(Boolean)
		.map(prettifyToken);

	let result = tokens.join(" ");
	result = result
		.replace(/\bGPT\s+/g, "GPT-")
		.replace(/\bGPT-(\d(?:\.\d)?)(\s+)([A-Za-z])/g, "GPT-$1 $3")
		.replace(/\bClaude\s+(\d(?:\.\d)?)/g, "Claude $1")
		.replace(/\bGemini\s+(\d(?:\.\d)?)/g, "Gemini $1")
		.replace(/\bLlama\s+(\d(?:\.\d)?)/g, "Llama $1")
		.replace(/\bQwen\s+(\d(?:\.\d)?)/g, "Qwen $1")
		.replace(/\bDeepSeek\s+R(\d)\b/g, "DeepSeek R$1")
		.replace(/\bDeepSeek\s+V(\d)\b/g, "DeepSeek V$1")
		.replace(/\s+/g, " ")
		.trim();
	return result || "AI Model";
}

function displayNameForModel(raw: any) {
	const providerModelId = String(raw?.id ?? "");
	const vendor = modelVendor(providerModelId);
	const upstreamName = typeof raw?.name === "string" ? raw.name.trim() : "";
	const tail = providerModelId.split("/").slice(1).join("/") || providerModelId;
	const cleanedName = upstreamName
		.replace(/^[A-Za-z0-9 .+\-]+:\s*/, "")
		.replace(/\s*\(free\)\s*/gi, "")
		.replace(/:free\b/gi, "")
		.replace(/\s+/g, " ")
		.trim();
	if (cleanedName && !/^[a-z0-9._/-]+$/i.test(cleanedName)) {
		return cleanedName;
	}
	if (providerModelId === "openrouter/auto") {
		return "Auto Router";
	}
	const pretty = prettifyModelTail(tail);
	return pretty === "AI Model" ? `${vendorLabel(vendor)} Model` : pretty;
}

function pricingTierForModel(raw: any, providerModelId: string): "free" | "paid" {
	if (providerModelId.includes(":free")) return "free";
	const prompt = Number(raw?.pricing?.prompt ?? raw?.pricing?.input ?? 0);
	const completion = Number(raw?.pricing?.completion ?? raw?.pricing?.output ?? 0);
	return prompt === 0 && completion === 0 ? "free" : "paid";
}

function capabilitiesForModel(raw: any, providerModelId: string) {
	const capabilities = new Set<string>(["streaming", "chat"]);
	const supported = Array.isArray(raw?.supported_parameters) ? raw.supported_parameters : [];
	if (supported.includes("tools")) capabilities.add("tools");
	if (supported.includes("reasoning") || supported.includes("include_reasoning")) capabilities.add("reasoning");
	if (supported.includes("image_url") || supported.includes("input_image") || supported.includes("images")) capabilities.add("vision");
	if (supported.includes("image_generation") || supported.includes("response_format") || supported.includes("size")) capabilities.add("image_generation");
	if (Array.isArray(raw?.architecture?.input_modalities) && raw.architecture.input_modalities.includes("image")) capabilities.add("vision");
	if (Array.isArray(raw?.architecture?.output_modalities) && raw.architecture.output_modalities.includes("image")) capabilities.add("image_generation");
	if (/flux|stable-diffusion|sdxl|dall-e|recraft|playground|imagen/i.test(providerModelId)) capabilities.add("image_generation");
	if (providerModelId === "openrouter/auto") {
		capabilities.add("tools");
		capabilities.add("reasoning");
		capabilities.add("vision");
	}
	return [...capabilities];
}

async function ensureBootstrapUsers(env: Env) {
	if (bootstrapInitPromise) return bootstrapInitPromise;
	bootstrapInitPromise = (async () => {
		if (!envBool(env, "TAI_BOOTSTRAP_ENABLE", false)) return;

		const alreadySeeded = await getMeta(env, "bootstrap_users_seeded_at");
		if (alreadySeeded) return;

		const createdAt = nowIso();
		const adminEmail = envString(env, "TAI_BOOTSTRAP_ADMIN_EMAIL").trim().toLowerCase();
		const adminPassword = envString(env, "TAI_BOOTSTRAP_ADMIN_PASSWORD");
		const adminUsername = envString(env, "TAI_BOOTSTRAP_ADMIN_USERNAME").trim() || "admin";
		const adminDisplayName = envString(env, "TAI_BOOTSTRAP_ADMIN_DISPLAY_NAME").trim() || "TAI Admin";

		const seedUsers: Array<{ email: string; password: string; username: string; displayName: string; role: Role; overridePlanTier?: PlanTier }> = [];
		if (adminEmail && adminPassword.length >= 12) {
			seedUsers.push({
				email: adminEmail,
				password: adminPassword,
				username: adminUsername,
				displayName: adminDisplayName,
				role: "ADMIN",
			});
		}

		const seedDefaultUser = envBool(env, "TAI_BOOTSTRAP_USER_ENABLE", false);
		const userEmail = envString(env, "TAI_BOOTSTRAP_USER_EMAIL").trim().toLowerCase();
		const userPassword = envString(env, "TAI_BOOTSTRAP_USER_PASSWORD");
		const userUsername = envString(env, "TAI_BOOTSTRAP_USER_USERNAME").trim() || "user";
		const userDisplayName = envString(env, "TAI_BOOTSTRAP_USER_DISPLAY_NAME").trim() || "TAI User";
		if (seedDefaultUser && userEmail && userPassword.length >= 12) {
			seedUsers.push({
				email: userEmail,
				password: userPassword,
				username: userUsername,
				displayName: userDisplayName,
				role: "USER",
			});
		}

		// App Store reviewer test account (always seeded when bootstrap is enabled)
		seedUsers.push({
			email: "appreviewer@gravitilabs.com",
			password: "TabaReview2026!",
			username: "appreviewer",
			displayName: "App Reviewer",
			role: "USER",
			overridePlanTier: "pro",
		});

		if (seedUsers.length === 0) return;

		for (const bootstrapUser of seedUsers) {
			const existing = await queryFirst<Pick<UserRow, "id">>(
				env.DB,
				"SELECT id FROM users WHERE lower(email) = lower(?) LIMIT 1",
				bootstrapUser.email,
			);
			if (existing?.id) {
				await exec(
					env.DB,
					"INSERT INTO user_settings (user_id, theme, language, notifications_enabled, voice_session_enabled, updated_at) VALUES (?, 'system', 'en', 1, 0, ?) ON CONFLICT(user_id) DO NOTHING",
					existing.id,
					createdAt,
				);
				continue;
			}

			const userId = randomId();
			const planTier = bootstrapUser.overridePlanTier ?? (bootstrapUser.role === "ADMIN" ? "POWER" : "FREE");
			await exec(
				env.DB,
				"INSERT INTO users (id, email, username, display_name, password_hash, role, status, plan_tier, email_verified_at, session_version, last_active_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, 'ENABLED', ?, ?, 0, NULL, ?, ?)",
				userId,
				bootstrapUser.email,
				bootstrapUser.username,
				bootstrapUser.displayName,
				await hashPassword(bootstrapUser.password),
				bootstrapUser.role,
				planTier,
				createdAt,
				createdAt,
				createdAt,
			);
			await exec(
				env.DB,
				"INSERT INTO user_settings (user_id, theme, language, notifications_enabled, voice_session_enabled, updated_at) VALUES (?, 'system', 'en', 1, 0, ?) ON CONFLICT(user_id) DO NOTHING",
				userId,
				createdAt,
			);
		}

		await setMeta(env, "bootstrap_users_seeded_at", createdAt);
	})();
	return bootstrapInitPromise;
}

export async function getUserById(env: Env, userId: string) {
	const row = await queryFirst<UserRow>(
		env.DB,
		"SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE id = ? LIMIT 1",
		userId,
	);
	if (!row) return null;
	const entitlement = await getEffectiveEntitlementForUser(env, row.id);
	return mapUser(row, entitlement);
}

export async function authenticateUser(env: Env, email: string, password: string) {
	await ensureBootstrapUsers(env);
	const row = await queryFirst<UserRow>(
		env.DB,
		"SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE lower(email) = lower(?) LIMIT 1",
		email,
	);
	if (!row || row.status !== "ENABLED") return { ok: false as const, code: "INVALID_CREDENTIALS" as const };
	if (!(await verifyPassword(password, row.password_hash))) return { ok: false as const, code: "INVALID_CREDENTIALS" as const };
	if (!row.email_verified_at) return { ok: false as const, code: "EMAIL_NOT_VERIFIED" as const };
	await exec(env.DB, "UPDATE users SET last_active_at = ?, updated_at = ? WHERE id = ?", nowIso(), nowIso(), row.id);
	const entitlement = await getEffectiveEntitlementForUser(env, row.id);
	return { ok: true as const, user: mapUser(row, entitlement) };
}

async function getSettingsRow(env: Env, userId: string): Promise<SettingsRecord> {
	const row = await queryFirst<D1Row>(
		env.DB,
		"SELECT theme, language, notifications_enabled, voice_session_enabled FROM user_settings WHERE user_id = ? LIMIT 1",
		userId,
	);
	if (!row) {
		await exec(
			env.DB,
			"INSERT INTO user_settings (user_id, theme, language, notifications_enabled, voice_session_enabled, updated_at) VALUES (?, ?, ?, 1, 0, ?)",
			userId,
			DEFAULT_SETTINGS.theme,
			DEFAULT_SETTINGS.language,
			nowIso(),
		);
		return { ...DEFAULT_SETTINGS };
	}
	return {
		theme: String(row.theme ?? DEFAULT_SETTINGS.theme),
		language: String(row.language ?? DEFAULT_SETTINGS.language),
		notificationsEnabled: boolFrom(row.notifications_enabled),
		voiceSessionEnabled: boolFrom(row.voice_session_enabled),
	};
}

export async function getSettings(user: UserProfile, env: Env) {
	return getSettingsRow(env, user.id);
}

export async function updateSettings(user: UserProfile, env: Env, input: z.infer<typeof settingsPatchSchema>) {
	const current = await getSettingsRow(env, user.id);
	const next = { ...current, ...input };
	await exec(
		env.DB,
		"INSERT INTO user_settings (user_id, theme, language, notifications_enabled, voice_session_enabled, updated_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET theme=excluded.theme, language=excluded.language, notifications_enabled=excluded.notifications_enabled, voice_session_enabled=excluded.voice_session_enabled, updated_at=excluded.updated_at",
		user.id,
		next.theme,
		next.language,
		next.notificationsEnabled ? 1 : 0,
		next.voiceSessionEnabled ? 1 : 0,
		nowIso(),
	);
	return next;
}

export async function updateAccount(user: UserProfile, env: Env, input: z.infer<typeof settingsAccountSchema>) {
	const nextEmail = input.email?.trim() || user.email;
	const current = await queryFirst<UserRow>(
		env.DB,
		"SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE id = ? LIMIT 1",
		user.id,
	);
	if (!current) {
		return { user: null, errorCode: "USER_NOT_FOUND" as const };
	}
	let nextPasswordHash: string | null = null;
	if (input.password) {
		if (!input.currentPassword) {
			return { user: null, errorCode: "CURRENT_PASSWORD_REQUIRED" as const };
		}
		const valid = await verifyPassword(input.currentPassword, current.password_hash);
		if (!valid) {
			return { user: null, errorCode: "CURRENT_PASSWORD_INVALID" as const };
		}
		nextPasswordHash = await hashPassword(input.password);
	}
	await exec(
		env.DB,
		`UPDATE users SET email = ?, updated_at = ?${nextPasswordHash ? ", password_hash = ?, session_version = session_version + 1, last_active_at = NULL" : ""} WHERE id = ?`,
		...(nextPasswordHash ? [nextEmail, nowIso(), nextPasswordHash, user.id] : [nextEmail, nowIso(), user.id]),
	);
	return { user: await getUserById(env, user.id), errorCode: null as const };
}

async function getFolderMap(env: Env, userId: string) {
	const rows = await queryAll<FolderRow>(
		env.DB,
		"SELECT id, user_id, name, color, created_at, updated_at FROM folders WHERE user_id = ? ORDER BY updated_at DESC",
		userId,
	);
	return new Map(
		rows.map((row) => [
			row.id,
			{
				id: row.id,
				name: row.name,
				color: row.color,
				createdAt: row.created_at,
				updatedAt: row.updated_at,
			} satisfies FolderRecord,
		]),
	);
}

export async function listFolders(user: UserProfile, env: Env) {
	return [...(await getFolderMap(env, user.id)).values()];
}

export async function createFolder(user: UserProfile, env: Env, input: z.infer<typeof folderCreateSchema>) {
	const id = randomId();
	const createdAt = nowIso();
	await exec(
		env.DB,
		"INSERT INTO folders (id, user_id, name, color, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
		id,
		user.id,
		input.name,
		input.color ?? null,
		createdAt,
		createdAt,
	);
	return { id, name: input.name, color: input.color ?? null, createdAt, updatedAt: createdAt } satisfies FolderRecord;
}

export async function updateFolder(user: UserProfile, env: Env, folderId: string, input: z.infer<typeof folderPatchSchema>) {
	const current = await queryFirst<FolderRow>(
		env.DB,
		"SELECT id, user_id, name, color, created_at, updated_at FROM folders WHERE id = ? AND user_id = ? LIMIT 1",
		folderId,
		user.id,
	);
	if (!current) return null;
	const name = input.name ?? current.name;
	const color = "color" in input ? input.color ?? null : current.color;
	const updatedAt = nowIso();
	await exec(env.DB, "UPDATE folders SET name = ?, color = ?, updated_at = ? WHERE id = ? AND user_id = ?", name, color, updatedAt, folderId, user.id);
	return { id: folderId, name, color, createdAt: current.created_at, updatedAt } satisfies FolderRecord;
}

export async function deleteFolder(user: UserProfile, env: Env, folderId: string) {
	await exec(env.DB, "UPDATE chats SET folder_id = NULL, updated_at = ? WHERE user_id = ? AND folder_id = ?", nowIso(), user.id, folderId);
	const result = await exec(env.DB, "DELETE FROM folders WHERE id = ? AND user_id = ?", folderId, user.id);
	return (result.meta.changes ?? 0) > 0;
}

async function getMessageRows(env: Env, chatId: string) {
	return queryAll<MessageRow>(
		env.DB,
		"SELECT id, chat_id, role, content, sequence, is_deleted, created_at, updated_at FROM messages WHERE chat_id = ? AND is_deleted = 0 ORDER BY sequence ASC",
		chatId,
	);
}

function mapMessage(row: MessageRow): MessageRecord {
	return {
		id: row.id,
		chatId: row.chat_id,
		role: row.role,
		content: row.content,
		sequence: row.sequence,
		isDeleted: boolFrom(row.is_deleted),
		createdAt: row.created_at,
		updatedAt: row.updated_at,
	};
}

async function listChatRowsForUser(env: Env, user: UserProfile, includeDeleted = false) {
	return queryAll<ChatRow>(
		env.DB,
		`SELECT id, user_id, folder_id, title, model_id, is_pinned, is_deleted, created_at, updated_at
		 FROM chats
		 WHERE user_id = ? ${includeDeleted ? "" : "AND is_deleted = 0"}
		 ORDER BY is_pinned DESC, updated_at DESC`,
		user.id,
	);
}

export async function getAccessibleModels(user: UserProfile, env: Env) {
	await syncModelsIfNeeded(env);
	// Filter to curated models only — this is the single enforcement point.
	// No reliance on is_enabled flag or migration timing.
	const curatedList = [...CURATED_PROVIDER_MODEL_IDS];
	const placeholders = curatedList.map(() => "?").join(", ");
	const rows = await queryAll<ModelRow>(
		env.DB,
		`SELECT id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at FROM models WHERE provider_model_id IN (${placeholders}) ORDER BY name ASC`,
		...curatedList,
	);
	// Log warnings for curated models not found in DB (sync may be lagging)
	const foundProviderIds = new Set(rows.map((r) => r.provider_model_id));
	for (const curatedId of CURATED_PROVIDER_MODEL_IDS) {
		if (!foundProviderIds.has(curatedId)) {
			console.warn(`Curated model not in DB: ${curatedId}`);
		}
	}
	if (user.role === "ADMIN") {
		return rows.map((row) => {
			const model = mapModel(row);
			const curatedTier = CURATED_MODELS[row.provider_model_id];
			return { ...model, requiredPlanTier: curatedTier ?? model.requiredPlanTier ?? "free", canAccess: true, lockReason: null };
		});
	}
	const assignedRows = await queryAll<{ model_id: string }>(env.DB, "SELECT model_id FROM user_permissions WHERE user_id = ?", user.id);
	const assigned = new Set(assignedRows.map((row) => row.model_id));
	const hasPermissionOverrides = assigned.size > 0;
	const hasStoreBackedPaidEntitlement = !!user.entitlement &&
		(user.entitlement.source === "apple" || user.entitlement.source === "google" || user.entitlement.source === "web") &&
		(user.entitlement.status === "active" || user.entitlement.status === "grace");
	const enforcePermissionWhitelist = hasPermissionOverrides && !hasStoreBackedPaidEntitlement;
	const models: ModelRecord[] = [];
	for (const row of rows) {
		const model = mapModel(row);
		if (model.category === "hidden-internal") continue;
		// Skip hidden internal models (free models used by TABAI routing only)
		if (HIDDEN_INTERNAL_MODELS.has(row.provider_model_id)) continue;
		// Use hardcoded tier from CURATED_MODELS instead of regex-based assignment
		const curatedTier = CURATED_MODELS[row.provider_model_id];
		const required: PlanTier = curatedTier ?? model.requiredPlanTier ?? "free";
		const planAllowed = PLAN_ORDER[user.planTier] >= PLAN_ORDER[required];
		const permissionAllowed = !enforcePermissionWhitelist || assigned.has(model.id);
		const canAccess = planAllowed && permissionAllowed;
		const lockReason = canAccess
			? null
			: !planAllowed
				? `Requires ${required.toUpperCase()} plan.`
				: "This model is not enabled for your account.";
		models.push({ ...model, requiredPlanTier: required, canAccess, lockReason });
	}
	return models;
}

function mapModel(row: ModelRow): ModelRecord {
	const vendorKey = row.vendor ?? "default";
	let capabilities: string[] = [];
	try {
		capabilities = JSON.parse(row.capabilities_json || "[]") as string[];
	} catch {
		capabilities = [];
	}
	capabilities = [...new Set(capabilities.map((value) => String(value).trim().toLowerCase()).filter(Boolean))];
	if (!capabilities.includes("chat")) capabilities.push("chat");
	if (!capabilities.includes("streaming")) capabilities.push("streaming");
	const normalizedSource = `${row.provider_model_id} ${row.name}`.toLowerCase();
	const supportsVision = capabilities.includes("vision");
	const supportsImageGeneration = capabilities.includes("image_generation") || /flux|stable-diffusion|sdxl|dall-e|recraft|playground|imagen/i.test(normalizedSource);
	const supportsReasoning = capabilities.includes("reasoning") || /\bo1\b|\bo3\b|reason|\br1\b|qwq/i.test(normalizedSource);
	let supportsTextChat = !supportsImageGeneration || capabilities.includes("chat") || /gpt|claude|gemini|llama|qwen|mistral|deepseek|grok/i.test(normalizedSource);
	// Free check comes first: a model with pricing_tier "free" or ":free" suffix is always
	// free-basic regardless of other capabilities (vision, reasoning, etc.), so it is not
	// incorrectly gated behind the Starter plan.
	const isFreeModel = row.pricing_tier === "free" || /:free\b|\bfree\b/i.test(normalizedSource);
	let category: ModelCategory = "fast-everyday";
	// Category assignment — based on model NAME patterns, NOT capabilities.
	// Many models report "vision" capability but are primarily text models (GPT-4o, Sonnet, etc.)
	// Vision capability is preserved as a feature flag but doesn't determine tier.
	if (/embedding|moderation|rerank|transcription|tts|whisper/i.test(normalizedSource)) {
		category = "hidden-internal";
	} else if (isFreeModel) {
		category = "free-basic";
	} else if (supportsImageGeneration) {
		category = "image-generation";
	} else if (/opus|ultra|\bmax\b|gpt-5|claude-4|grok-[34](?!.*mini)/i.test(normalizedSource)) {
		category = "premium-creative";
	} else if (supportsReasoning) {
		category = "premium-reasoning";
	} else if (/\bvision\b.*instruct|vl\b/i.test(normalizedSource)) {
		// Only models with "vision" explicitly in their name (e.g. "Llama 3.2 11B Vision Instruct")
		category = "image-vision";
	} else {
		category = "fast-everyday";
	}
	// Tier assignment: more granular than just category
	let requiredPlanTier: PlanTier = "starter";
	if (category === "free-basic") {
		requiredPlanTier = "free";
	} else if (category === "hidden-internal") {
		requiredPlanTier = "power";
	} else if (category === "premium-creative") {
		// Opus, GPT-5, Claude 4, Grok 3/4 (non-mini) → Power
		requiredPlanTier = /opus|ultra|\bmax\b|gpt-5|claude-4|grok-[34](?!.*mini)/i.test(normalizedSource) ? "power" : "pro";
	} else if (category === "premium-reasoning") {
		// O1, O3 (non-mini), O3-Pro → Power; everything else (O3-mini, O4-mini, R1, QwQ) → Pro
		requiredPlanTier = /\bo3\b(?!.*mini)|\bo1\b(?!.*mini)|o3-pro/i.test(normalizedSource) ? "power" : "pro";
	} else if (category === "image-generation") {
		requiredPlanTier = "pro";
	} else if (category === "image-vision") {
		requiredPlanTier = "starter";
	} else {
		// fast-everyday: differentiate between cheap (Starter) and expensive (Pro/Power) models
		const isPowerTierModel = /sonnet.*4\.[6-9]|sonnet.*[5-9]\.|gpt-4-turbo/i.test(normalizedSource);
		const isProTierModel = /gpt-4o(?!.*mini)|gpt-4\.[1-9](?!.*(?:mini|nano))|claude.*sonnet|claude-sonnet|gemini.*pro|mistral.*large|llama.*405b|sonar.*pro|grok-[23](?!.*beta)|grok-\d.*mini/i.test(normalizedSource);
		requiredPlanTier = isPowerTierModel ? "power" : isProTierModel ? "pro" : "starter";
	}
	if (category === "hidden-internal") requiredPlanTier = "power";
	if (category === "hidden-internal") supportsTextChat = false;
	if (category === "image-generation" && !/gpt|claude|gemini|llama|qwen|mistral|deepseek|grok/i.test(normalizedSource)) supportsTextChat = false;
	return {
		id: row.id,
		providerId: PROVIDER.id,
		slug: row.id.replace(/^or-/, ""),
		providerModelId: row.provider_model_id,
		displayName: (row.name || "").replace(/\s*\(free\)\s*/gi, "").replace(/:free\b/gi, "").trim(),
		logoUrl: row.logo || modelLogo(vendorKey),
		description: row.description,
		enabled: boolFrom(row.is_enabled),
		supportsStreaming: true,
		supportsTextChat,
		supportsVision,
		supportsReasoning,
		supportsImageGeneration,
		vendor: vendorLabel(vendorKey),
		capabilities,
		verified: boolFrom(row.verified),
		verificationStatus: boolFrom(row.verified) ? "verified" : "unverified",
		contextLength: row.context_length,
		pricingTier: row.pricing_tier,
		category,
		requiredPlanTier,
		canAccess: true,
		lockReason: null,
		provider: { ...PROVIDER },
	};
}

async function getModelById(env: Env, modelId: string) {
	await syncModelsIfNeeded(env);
	const row = await queryFirst<ModelRow>(
		env.DB,
		"SELECT id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at FROM models WHERE id = ? LIMIT 1",
		modelId,
	);
	return row ? mapModel(row) : null;
}

async function getMessagesByChatIds(env: Env, chatIds: string[]) {
	if (chatIds.length === 0) return new Map<string, MessageRecord[]>();
	const placeholders = chatIds.map(() => "?").join(", ");
	const rows = await queryAll<MessageRow>(
		env.DB,
		`SELECT id, chat_id, role, content, sequence, is_deleted, created_at, updated_at
		 FROM messages
		 WHERE chat_id IN (${placeholders}) AND is_deleted = 0
		 ORDER BY sequence ASC`,
		...chatIds,
	);
	const grouped = new Map<string, MessageRecord[]>();
	for (const row of rows) {
		const list = grouped.get(row.chat_id) ?? [];
		list.push(mapMessage(row));
		grouped.set(row.chat_id, list);
	}
	return grouped;
}

export async function serializeChats(user: UserProfile, env: Env, includeDeleted = false) {
	const chats = await listChatRowsForUser(env, user, includeDeleted);
	const folders = await getFolderMap(env, user.id);
	const models = new Map((await getAccessibleModels(user, env)).map((model) => [model.id, model]));
	const missingModelIds = [...new Set(chats.map((chat) => chat.model_id).filter((value): value is string => !!value && !models.has(value)))];
	for (const modelId of missingModelIds) {
		const model = await getModelById(env, modelId);
		if (model) models.set(modelId, model);
	}
	const messages = await getMessagesByChatIds(env, chats.map((chat) => chat.id));
	return chats.map((row) => ({
		id: row.id,
		userId: row.user_id,
		folderId: row.folder_id,
		title: row.title,
		modelId: row.model_id,
		isPinned: boolFrom(row.is_pinned),
		isDeleted: boolFrom(row.is_deleted),
		createdAt: row.created_at,
		updatedAt: row.updated_at,
		folder: row.folder_id ? folders.get(row.folder_id) ?? null : null,
		model: row.model_id ? models.get(row.model_id) ?? null : null,
		messages: (messages.get(row.id) ?? []).slice(-1),
	} satisfies ChatRecord));
}

export async function getChat(user: UserProfile, env: Env, chatId: string) {
	const rows = await queryAll<ChatRow>(
		env.DB,
		"SELECT id, user_id, folder_id, title, model_id, is_pinned, is_deleted, created_at, updated_at FROM chats WHERE id = ? AND user_id = ? AND is_deleted = 0 LIMIT 1",
		chatId,
		user.id,
	);
	if (!rows[0]) return null;
	const chats = await serializeChats(user, env, true);
	return chats.find((chat) => chat.id === chatId && !chat.isDeleted) ?? null;
}

export async function createChat(user: UserProfile, env: Env, input: z.infer<typeof chatCreateSchema>) {
	const id = randomId();
	const createdAt = nowIso();
	await exec(
		env.DB,
		"INSERT INTO chats (id, user_id, title, model_id, folder_id, is_pinned, is_deleted, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?)",
		id,
		user.id,
		input.title?.trim() || "New chat",
		input.modelId ?? null,
		input.folderId ?? null,
		createdAt,
		createdAt,
	);
	return { id };
}

export async function updateChat(user: UserProfile, env: Env, chatId: string, input: z.infer<typeof chatPatchSchema>) {
	const current = await queryFirst<ChatRow>(
		env.DB,
		"SELECT id, user_id, folder_id, title, model_id, is_pinned, is_deleted, created_at, updated_at FROM chats WHERE id = ? AND user_id = ? LIMIT 1",
		chatId,
		user.id,
	);
	if (!current || boolFrom(current.is_deleted)) return null;
	await exec(
		env.DB,
		"UPDATE chats SET title = ?, folder_id = ?, model_id = ?, is_pinned = ?, updated_at = ? WHERE id = ? AND user_id = ?",
		input.title ?? current.title,
		"folderId" in input ? input.folderId ?? null : current.folder_id,
		"modelId" in input ? input.modelId ?? null : current.model_id,
		typeof input.isPinned === "boolean" ? (input.isPinned ? 1 : 0) : current.is_pinned,
		nowIso(),
		chatId,
		user.id,
	);
	return { id: chatId };
}

export async function deleteChat(user: UserProfile, env: Env, chatId: string, purge = false) {
	const result = purge && user.role === "ADMIN"
		? await exec(env.DB, "DELETE FROM chats WHERE id = ?", chatId)
		: await exec(env.DB, "UPDATE chats SET is_deleted = 1, updated_at = ? WHERE id = ? AND user_id = ?", nowIso(), chatId, user.id);
	return (result.meta.changes ?? 0) > 0;
}

export async function listMessages(user: UserProfile, env: Env, chatId: string) {
	const chat = user.role === "ADMIN"
		? await queryFirst<ChatRow>(env.DB, "SELECT id FROM chats WHERE id = ? LIMIT 1", chatId)
		: await queryFirst<ChatRow>(env.DB, "SELECT id FROM chats WHERE id = ? AND user_id = ? LIMIT 1", chatId, user.id);
	if (!chat) return null;
	const rows = await getMessageRows(env, chatId);
	return rows.map(mapMessage);
}

export async function createMessage(user: UserProfile, env: Env, chatId: string, input: z.infer<typeof messageCreateSchema>) {
	const chat = user.role === "ADMIN"
		? await queryFirst<ChatRow>(env.DB, "SELECT id FROM chats WHERE id = ? LIMIT 1", chatId)
		: await queryFirst<ChatRow>(env.DB, "SELECT id FROM chats WHERE id = ? AND user_id = ? LIMIT 1", chatId, user.id);
	if (!chat) return null;
	const last = await queryFirst<{ maxSeq: number | null }>(env.DB, "SELECT MAX(sequence) as maxSeq FROM messages WHERE chat_id = ?", chatId);
	const id = randomId();
	const createdAt = nowIso();
	await exec(
		env.DB,
		"INSERT INTO messages (id, chat_id, role, content, sequence, is_deleted, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, ?, ?)",
		id,
		chatId,
		input.role.toUpperCase(),
		input.content,
		(last?.maxSeq ?? -1) + 1,
		createdAt,
		createdAt,
	);
	await exec(env.DB, "UPDATE chats SET updated_at = ?, title = CASE WHEN title = 'New chat' AND ? = 'USER' THEN substr(?, 1, 80) ELSE title END WHERE id = ?", createdAt, input.role.toUpperCase(), input.content.trim() || "New chat", chatId);
	return {
		id,
		chatId,
		role: input.role.toUpperCase(),
		content: input.content,
		sequence: (last?.maxSeq ?? -1) + 1,
		isDeleted: false,
		createdAt,
		updatedAt: createdAt,
	} satisfies MessageRecord;
}

async function getMeta(env: Env, key: string) {
	const row = await queryFirst<{ value: string }>(env.DB, "SELECT value FROM app_meta WHERE key = ? LIMIT 1", key);
	return row?.value ?? null;
}

async function setMeta(env: Env, key: string, value: string) {
	await exec(env.DB, "INSERT INTO app_meta (key, value, updated_at) VALUES (?, ?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value, updated_at=excluded.updated_at", key, value, nowIso());
}

export async function syncModelsIfNeeded(env: Env, force = false) {
	const syncedAt = await getMeta(env, "models_synced_at");
	if (!force && syncedAt && Date.now() - Date.parse(syncedAt) < 1000 * 60 * 60) {
		return;
	}
	const headers = new Headers({
		"HTTP-Referer": "https://ai.gravitilabs.com",
		"X-Title": "TABAI",
	});
	if (env.OPENROUTER_API_KEY) headers.set("Authorization", `Bearer ${env.OPENROUTER_API_KEY}`);
	const res = await fetch("https://openrouter.ai/api/v1/models", { headers });
	if (!res.ok) throw new Error(`OpenRouter models failed (${res.status})`);
	const json = await res.json<any>();
	const models = Array.isArray(json?.data) ? json.data : [];
	const now = nowIso();
	for (const raw of models) {
		const providerModelId = String(raw.id);
		const vendor = modelVendor(providerModelId);
		const capabilities = capabilitiesForModel(raw, providerModelId);
		const id = `or-${providerModelId.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")}`;
		await exec(
			env.DB,
			`INSERT INTO models (id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at)
			 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
			 ON CONFLICT(id) DO UPDATE SET
			   provider_model_id=excluded.provider_model_id,
			   name=excluded.name,
			   vendor=excluded.vendor,
			   logo=excluded.logo,
			   description=excluded.description,
			   capabilities_json=excluded.capabilities_json,
			   context_length=excluded.context_length,
			   pricing_tier=excluded.pricing_tier,
			   verified=1,
			   updated_at=excluded.updated_at`,
			id,
			providerModelId,
			displayNameForModel(raw),
			vendor,
			modelLogo(vendor),
			typeof raw.description === "string" ? raw.description : null,
			JSON.stringify(capabilities),
			typeof raw.context_length === "number" ? raw.context_length : null,
			pricingTierForModel(raw, providerModelId),
			0, // is_enabled not used for curation; CURATED_PROVIDER_MODEL_IDS enforced at query time
			now,
			now,
		);
	}
	await setMeta(env, "models_synced_at", now);
}

// Single source of truth for which models are shown AND their tier.
// No regex guessing — tier is explicitly assigned per model.
// Verified against OpenRouter's live API.
const CURATED_MODELS: Record<string, PlanTier> = {
	// ── TABAI composite (the ONLY free-tier model visible to users) ──
	"tabai": "free",
	// ── Starter (12) ──
	"openai/gpt-4o-mini": "starter",
	"openai/gpt-4.1-mini": "starter",
	"openai/gpt-4.1-nano": "starter",
	"anthropic/claude-3.5-haiku": "starter",
	"anthropic/claude-haiku-4.5": "starter",
	"google/gemini-2.0-flash-001": "starter",
	"google/gemini-2.5-flash": "starter",
	"meta-llama/llama-3.3-70b-instruct": "starter",
	"mistralai/mistral-small-3.1-24b-instruct": "starter",
	"qwen/qwen-2.5-72b-instruct": "starter",
	"deepseek/deepseek-chat": "starter",
	"meta-llama/llama-3.2-11b-vision-instruct": "starter",
	// ── Pro (14) ──
	"openai/gpt-4o": "pro",
	"openai/gpt-4.1": "pro",
	"anthropic/claude-3.5-sonnet": "pro",
	"anthropic/claude-sonnet-4": "pro",
	"anthropic/claude-sonnet-4.5": "pro",
	"google/gemini-2.5-pro": "pro",
	"deepseek/deepseek-r1": "pro",
	"deepseek/deepseek-r1-0528": "pro",
	"mistralai/mistral-large": "pro",
	"qwen/qwq-32b": "pro",
	"openai/o3-mini": "pro",
	"openai/o4-mini": "pro",
	"x-ai/grok-3-mini": "pro",
	"perplexity/sonar-pro": "pro",
	// ── Power (10) ──
	"anthropic/claude-opus-4": "power",
	"anthropic/claude-opus-4.5": "power",
	"anthropic/claude-sonnet-4.6": "power",
	"openai/o1": "power",
	"openai/o3": "power",
	"openai/o3-pro": "power",
	"openai/gpt-4-turbo": "power",
	"openai/gpt-5": "power",
	"x-ai/grok-3": "power",
	"x-ai/grok-4": "power",
};
// Hidden internal models — used by TABAI routing but not shown in model picker.
// These are free OpenRouter models that TABAI routes to behind the scenes.
const HIDDEN_INTERNAL_MODELS = new Set([
	"meta-llama/llama-3.2-3b-instruct:free",
	"meta-llama/llama-3.3-70b-instruct:free",
	"google/gemma-3-4b-it:free",
	"google/gemma-3-12b-it:free",
	"google/gemma-3-27b-it:free",
	"mistralai/mistral-small-3.1-24b-instruct:free",
	"nousresearch/hermes-3-llama-3.1-405b:free",
	"nvidia/nemotron-nano-9b-v2:free",
]);
const CURATED_PROVIDER_MODEL_IDS = new Set([...Object.keys(CURATED_MODELS), ...HIDDEN_INTERNAL_MODELS]);

export async function serializeBootstrap(user: UserProfile, env: Env) {
	return {
		user,
		models: await getAccessibleModels(user, env),
		chats: await serializeChats(user, env),
		settings: await getSettings(user, env),
	};
}

export async function listUsers(env: Env) {
	const rows = await queryAll<UserRow>(env.DB, "SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE status != 'DELETED' ORDER BY created_at ASC");
	const entitlements = await getEffectiveEntitlementsByUserIds(env, rows.map((row) => row.id));
	return rows.map((row) => mapUser(row, entitlements.get(row.id) ?? null));
}

export function streamOutputCharLimit(env: Env) {
	return envInt(env, "TAI_STREAM_OUTPUT_CHAR_LIMIT", 24000, 1000, 1000000);
}

export async function createUser(env: Env, actor: UserProfile, input: z.infer<typeof adminUserCreateSchema>) {
	const id = randomId();
	const createdAt = nowIso();
	await exec(
		env.DB,
		"INSERT INTO users (id, email, username, display_name, password_hash, role, status, plan_tier, email_verified_at, session_version, last_active_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, 'ENABLED', ?, ?, 0, NULL, ?, ?)",
		id,
		input.email,
		input.username,
		input.displayName?.trim() || null,
		await hashPassword(input.password),
		input.role,
		normalizePlanTier(input.planTier),
		createdAt,
		createdAt,
		createdAt,
	);
	await exec(env.DB, "INSERT INTO user_settings (user_id, theme, language, notifications_enabled, voice_session_enabled, updated_at) VALUES (?, 'system', 'en', 1, 0, ?)", id, createdAt);
	await logAudit(env, actor, "user.create", "user", id, { email: input.email, role: input.role });
	return getUserById(env, id);
}

export async function patchUser(env: Env, actor: UserProfile, userId: string, input: z.infer<typeof adminUserPatchSchema>) {
	const current = await queryFirst<UserRow>(
		env.DB,
		"SELECT id, email, username, display_name, role, status, plan_tier, password_hash, email_verified_at, session_version, last_active_at, created_at, updated_at FROM users WHERE id = ? LIMIT 1",
		userId,
	);
	if (!current) return null;
	const nextPasswordHash = input.password ? await hashPassword(input.password) : current.password_hash;
	await exec(
		env.DB,
		`UPDATE users SET email = ?, username = ?, display_name = ?, password_hash = ?, status = ?, plan_tier = ?, updated_at = ?${input.password ? ", session_version = session_version + 1, last_active_at = NULL" : ""} WHERE id = ?`,
		input.email ?? current.email,
		input.username ?? current.username,
		"displayName" in input ? input.displayName ?? null : current.display_name,
		nextPasswordHash,
		input.status ?? current.status,
		normalizePlanTier(input.planTier ?? current.plan_tier),
		nowIso(),
		userId,
	);
	await logAudit(env, actor, "user.update", "user", userId, input);
	return getUserById(env, userId);
}

type UpsertEntitlementInput = {
	userId: string;
	planTier: PlanTier;
	source: EntitlementSource;
	status: EntitlementStatus;
	startAt?: string;
	expiresAt?: string | null;
	autoRenew?: boolean;
	externalProductId?: string | null;
	externalOriginalTransactionId?: string | null;
	lastValidatedAt?: string | null;
	metadataJson?: string | null;
};

async function upsertUserEntitlement(env: Env, input: UpsertEntitlementInput) {
	await ensureEntitlementTables(env);
	const now = nowIso();
	const startAt = input.startAt ?? now;
	const existing = input.externalOriginalTransactionId
		? await queryFirst<{ id: string }>(
			env.DB,
			"SELECT id FROM user_entitlements WHERE user_id = ? AND source = ? AND external_original_transaction_id = ? LIMIT 1",
			input.userId,
			input.source,
			input.externalOriginalTransactionId,
		)
		: null;
	const id = existing?.id ?? randomId();
	if (existing) {
		await exec(
			env.DB,
			`UPDATE user_entitlements
			 SET plan_tier = ?, status = ?, start_at = ?, expires_at = ?, auto_renew = ?, external_product_id = ?, external_original_transaction_id = ?, last_validated_at = ?, metadata_json = ?, updated_at = ?
			 WHERE id = ?`,
			normalizePlanTier(input.planTier),
			normalizeEntitlementStatus(input.status),
			startAt,
			input.expiresAt ?? null,
			input.autoRenew ? 1 : 0,
			input.externalProductId ?? null,
			input.externalOriginalTransactionId ?? null,
			input.lastValidatedAt ?? null,
			input.metadataJson ?? null,
			now,
			id,
		);
	} else {
		await exec(
			env.DB,
			`INSERT INTO user_entitlements
			 (id, user_id, plan_tier, source, status, start_at, expires_at, auto_renew, external_product_id, external_original_transaction_id, last_validated_at, metadata_json, created_at, updated_at)
			 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
			id,
			input.userId,
			normalizePlanTier(input.planTier),
			normalizeEntitlementSource(input.source),
			normalizeEntitlementStatus(input.status),
			startAt,
			input.expiresAt ?? null,
			input.autoRenew ? 1 : 0,
			input.externalProductId ?? null,
			input.externalOriginalTransactionId ?? null,
			input.lastValidatedAt ?? null,
			input.metadataJson ?? null,
			now,
			now,
		);
	}
	const latest = await queryFirst<EntitlementRow>(
		env.DB,
		`SELECT id, user_id, plan_tier, source, status, start_at, expires_at, auto_renew, external_product_id, external_original_transaction_id, last_validated_at, metadata_json, created_at, updated_at
		 FROM user_entitlements
		 WHERE id = ?
		 LIMIT 1`,
		id,
	);
	return mapEntitlement(latest);
}

export async function getUserEntitlement(env: Env, userId: string) {
	const effective = await getEffectiveEntitlementForUser(env, userId);
	const latest = await getLatestEntitlementForUser(env, userId);
	return {
		effective,
		latest,
	};
}

export async function setAdminUserEntitlement(env: Env, actor: UserProfile, userId: string, input: z.infer<typeof adminEntitlementPatchSchema>) {
	const target = await queryFirst<{ id: string }>(env.DB, "SELECT id FROM users WHERE id = ? LIMIT 1", userId);
	if (!target) return null;
	const entitlement = await upsertUserEntitlement(env, {
		userId,
		planTier: normalizePlanTier(input.planTier),
		source: normalizeEntitlementSource(input.source),
		status: normalizeEntitlementStatus(input.status),
		startAt: input.startAt ?? nowIso(),
		expiresAt: "expiresAt" in input ? input.expiresAt ?? null : null,
		autoRenew: input.autoRenew ?? false,
		externalProductId: "externalProductId" in input ? input.externalProductId ?? null : null,
		externalOriginalTransactionId: "externalOriginalTransactionId" in input ? input.externalOriginalTransactionId ?? null : null,
		lastValidatedAt: nowIso(),
		metadataJson: JSON.stringify({ assignedBy: actor.id, mode: "admin_override" }),
	});
	await logAudit(env, actor, "entitlement.override", "user", userId, {
		planTier: input.planTier,
		source: input.source,
		status: input.status,
		expiresAt: input.expiresAt ?? null,
	});
	return entitlement;
}

type StoreVerificationState = "verified" | "pending_validation" | "invalid" | "error";

type StoreVerificationResult = {
	provider: "apple" | "google";
	state: StoreVerificationState;
	code: string;
	message: string;
	productId: string | null;
	originalTransactionId: string | null;
	status: EntitlementStatus;
	expiresAt: string | null;
	autoRenew: boolean;
	verificationReference: string | null;
	rawSummary: Record<string, unknown>;
};

type StoreSyncResponse = {
	accepted: boolean;
	provider: "apple" | "google";
	verificationState: StoreVerificationState;
	code: string;
	message: string;
	entitlement: EntitlementRecord | null;
	latestEntitlement: EntitlementRecord | null;
	debugSummary?: string | null;
};

function errorDebugMessage(error: unknown) {
	if (error instanceof Error) return error.message;
	return String(error);
}

function pushDebugStage(stages: string[], stage: string, details?: Record<string, unknown>) {
	const rendered = details
		? Object.entries(details)
			.map(([key, value]) => {
				const formatted = formatStoreDebugValue(value);
				return formatted == null ? null : `${key}=${formatted}`;
			})
			.filter((value): value is string => !!value)
			.join(",")
		: "";
	stages.push(rendered ? `${stage}(${rendered})` : stage);
}

function buildStructuredSyncResponse(input: {
	provider: "apple" | "google";
	verificationState: StoreVerificationState;
	code: string;
	message: string;
	entitlement?: EntitlementRecord | null;
	latestEntitlement?: EntitlementRecord | null;
	debugSummary?: string | null;
}): StoreSyncResponse {
	return {
		accepted: true,
		provider: input.provider,
		verificationState: input.verificationState,
		code: input.code,
		message: input.message,
		entitlement: input.entitlement ?? null,
		latestEntitlement: input.latestEntitlement ?? null,
		debugSummary: input.debugSummary ?? null,
	};
}

function formatStoreDebugValue(value: unknown) {
	if (value === null || value === undefined) return null;
	if (typeof value === "string") {
		const trimmed = value.trim();
		return trimmed ? trimmed : null;
	}
	if (typeof value === "number" || typeof value === "boolean") {
		return String(value);
	}
	try {
		const encoded = JSON.stringify(value);
		return encoded.length > 400 ? `${encoded.slice(0, 397)}...` : encoded;
	} catch {
		return String(value);
	}
}

function buildStoreSyncDebugSummary(
	env: Env,
	input: StoreEntitlementSyncInput,
	verification: StoreVerificationResult,
	mappedPlanTier: PlanTier | null,
) {
	const parts: Array<[string, unknown]> = [
		["provider", verification.provider],
		["state", verification.state],
		["code", verification.code],
		["requestProductId", input.productId ?? null],
		["resolvedProductId", verification.productId],
		["resolvedOriginalTransactionId", verification.originalTransactionId],
		["mappedPlanTier", mappedPlanTier],
		["raw", verification.rawSummary],
	];

	if (input.provider === "apple") {
		const hasPlanMap = envString(env, "TAI_STORE_PRODUCT_PLAN_MAP").trim().length > 0;
		parts.push(
			["environment", input.environment],
			["transactionId", input.transactionId],
			["originalTransactionId", input.originalTransactionId ?? null],
			["hasIssuerId", envString(env, "APPLE_APP_STORE_ISSUER_ID").trim().length > 0],
			["hasKeyId", envString(env, "APPLE_APP_STORE_KEY_ID").trim().length > 0],
			["hasPrivateKey", envString(env, "APPLE_APP_STORE_PRIVATE_KEY").trim().length > 0],
			["hasBundleId", envString(env, "APPLE_APP_STORE_BUNDLE_ID").trim().length > 0],
			["hasPlanMap", hasPlanMap],
		);
	} else {
		parts.push(
			["packageName", input.packageName],
			["purchaseTokenPresent", input.purchaseToken.length > 0],
		);
	}

	return parts
		.map(([key, value]) => {
			const rendered = formatStoreDebugValue(value);
			return rendered === null ? null : `${key}=${rendered}`;
		})
		.filter((value): value is string => !!value)
		.join(" | ");
}

function resolveProductPlanTier(
	env: Env,
	provider: "apple" | "google",
	productId: string,
): PlanTier | null {
	// Production should set TAI_STORE_PRODUCT_PLAN_MAP explicitly with provider-qualified keys.
	// Current Apple App Store mapping:
	// - apple:com.tai.starter.monthly => starter
	// - apple:com.tai.pro.monthly => pro
	// - apple:com.tai.power.monthly => power
	const raw = envString(env, "TAI_STORE_PRODUCT_PLAN_MAP").trim();
	if (raw) {
		try {
			const parsed = JSON.parse(raw) as Record<string, unknown>;
			const providerKey = `${provider}:${productId}`;
			const value = parsed[providerKey] ?? parsed[productId];
			if (value === "free" || value === "starter" || value === "pro" || value === "power") {
				return value;
			}
		} catch {
			// Ignore invalid map JSON and continue with heuristic fallback.
		}
	}
	if (/starter/i.test(productId)) return "starter";
	if (/\bpro\b/i.test(productId)) return "pro";
	if (/power|ultra|max/i.test(productId)) return "power";
	if (/free/i.test(productId)) return "free";
	return null;
}

function numberToIso(input: unknown) {
	const value = Number(input);
	if (!Number.isFinite(value) || value <= 0) return null;
	return new Date(value).toISOString();
}

async function getGoogleAccessToken(env: Env) {
	const serviceAccount = envString(env, "GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL").trim();
	const privateKey = envString(env, "GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY").trim();
	if (!serviceAccount || !privateKey) {
		return { ok: false as const, code: "GOOGLE_CONFIG_MISSING" as const, token: null as string | null };
	}
	const now = Math.floor(Date.now() / 1000);
	const assertion = await signJwtRs256(
		{ alg: "RS256", typ: "JWT" },
		{
			iss: serviceAccount,
			scope: "https://www.googleapis.com/auth/androidpublisher",
			aud: "https://oauth2.googleapis.com/token",
			iat: now,
			exp: now + 3600,
		},
		privateKey,
	);
	const body = new URLSearchParams();
	body.set("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
	body.set("assertion", assertion);
	const response = await fetch("https://oauth2.googleapis.com/token", {
		method: "POST",
		headers: { "Content-Type": "application/x-www-form-urlencoded" },
		body: body.toString(),
	});
	if (!response.ok) {
		return { ok: false as const, code: "GOOGLE_AUTH_FAILED" as const, token: null as string | null };
	}
	const json = await response.json() as { access_token?: string };
	if (!json.access_token) {
		return { ok: false as const, code: "GOOGLE_AUTH_FAILED" as const, token: null as string | null };
	}
	return { ok: true as const, code: "OK" as const, token: json.access_token };
}

async function verifyApplePurchase(env: Env, input: AppleStoreEntitlementSyncInput): Promise<StoreVerificationResult> {
	const stages: string[] = [];
	pushDebugStage(stages, "parsed_payload", {
		environment: input.environment,
		transactionId: input.transactionId,
		originalTransactionId: input.originalTransactionId ?? null,
		requestProductId: input.productId ?? null,
	});
	const issuerId = envString(env, "APPLE_APP_STORE_ISSUER_ID").trim();
	const keyId = envString(env, "APPLE_APP_STORE_KEY_ID").trim();
	const privateKey = envString(env, "APPLE_APP_STORE_PRIVATE_KEY").trim();
	const bundleId = envString(env, "APPLE_APP_STORE_BUNDLE_ID").trim();
	if (!issuerId || !keyId || !privateKey) {
		const missing: string[] = [];
		if (!issuerId) missing.push("APPLE_APP_STORE_ISSUER_ID");
		if (!keyId) missing.push("APPLE_APP_STORE_KEY_ID");
		if (!privateKey) missing.push("APPLE_APP_STORE_PRIVATE_KEY");
		return {
			provider: "apple",
			state: "pending_validation",
			code: "APPLE_CONFIG_MISSING",
			message: `Apple verification credentials are missing on backend: ${missing.join(", ")}.`,
			productId: input.productId ?? null,
			originalTransactionId: input.originalTransactionId ?? null,
			status: "inactive",
			expiresAt: null,
			autoRenew: false,
			verificationReference: input.transactionId,
			rawSummary: {
				stages,
				hasSignedTransactionInfo: !!input.signedTransactionInfo,
				environment: input.environment,
				missing,
				hasBundleId: !!bundleId,
			},
		};
	}

	const now = Math.floor(Date.now() / 1000);
	let token: string;
	try {
		token = await signJwtEs256(
			{ alg: "ES256", kid: keyId, typ: "JWT" },
			{
				iss: issuerId,
				iat: now,
				exp: now + 1200,
				aud: "appstoreconnect-v1",
				...(bundleId ? { bid: bundleId } : {}),
			},
			privateKey,
		);
		pushDebugStage(stages, "built_jwt", { hasBundleId: !!bundleId });
	} catch (error) {
		const code = error instanceof JwtSignError ? error.code : "APPLE_JWT_BUILD_FAILED";
		const message = error instanceof JwtSignError ? error.message : "Apple verification JWT could not be created.";
		return {
			provider: "apple",
			state: "error",
			code,
			message,
			productId: input.productId ?? null,
			originalTransactionId: input.originalTransactionId ?? null,
			status: "inactive",
			expiresAt: null,
			autoRenew: false,
			verificationReference: input.transactionId,
			rawSummary: { stages, error: errorDebugMessage(error), environment: input.environment },
		};
	}
	const baseUrl = input.environment === "sandbox"
		? "https://api.storekit-sandbox.itunes.apple.com"
		: "https://api.storekit.itunes.apple.com";
	let response: Response;
	try {
		response = await fetch(`${baseUrl}/inApps/v1/transactions/${encodeURIComponent(input.transactionId)}`, {
			headers: { Authorization: `Bearer ${token}` },
		});
		pushDebugStage(stages, "called_apple", { httpStatus: response.status, baseUrl });
	} catch (error) {
		return {
			provider: "apple",
			state: "error",
			code: "APPLE_VERIFY_REQUEST_FAILED",
			message: "Apple verification request could not be completed.",
			productId: input.productId ?? null,
			originalTransactionId: input.originalTransactionId ?? null,
			status: "inactive",
			expiresAt: null,
			autoRenew: false,
			verificationReference: input.transactionId,
			rawSummary: { stages, error: errorDebugMessage(error), environment: input.environment },
		};
	}
	if (response.status === 404) {
		return {
			provider: "apple",
			state: "invalid",
			code: "APPLE_TRANSACTION_NOT_FOUND",
			message: `Apple ${input.environment} verification returned 404 for transaction ${input.transactionId}.`,
			productId: input.productId ?? null,
			originalTransactionId: input.originalTransactionId ?? null,
			status: "inactive",
			expiresAt: null,
			autoRenew: false,
			verificationReference: input.transactionId,
			rawSummary: { stages, httpStatus: 404, environment: input.environment },
		};
	}
	if (!response.ok) {
		return {
			provider: "apple",
			state: "error",
			code: "APPLE_VERIFY_FAILED",
			message: `Apple verification request failed with HTTP ${response.status} in ${input.environment}.`,
			productId: input.productId ?? null,
			originalTransactionId: input.originalTransactionId ?? null,
			status: "inactive",
			expiresAt: null,
			autoRenew: false,
			verificationReference: input.transactionId,
			rawSummary: { stages, httpStatus: response.status, environment: input.environment },
		};
	}
	const appleText = await response.text();
	let json: { signedTransactionInfo?: string };
	try {
		json = JSON.parse(appleText) as { signedTransactionInfo?: string };
		pushDebugStage(stages, "parsed_apple_response", { hasSignedTransactionInfo: !!json.signedTransactionInfo });
	} catch (error) {
		return {
			provider: "apple",
			state: "error",
			code: "APPLE_RESPONSE_INVALID",
			message: "Apple verification response was not valid JSON.",
			productId: input.productId ?? null,
			originalTransactionId: input.originalTransactionId ?? null,
			status: "inactive",
			expiresAt: null,
			autoRenew: false,
			verificationReference: input.transactionId,
			rawSummary: {
				stages,
				error: errorDebugMessage(error),
				bodySnippet: appleText.slice(0, 400),
				environment: input.environment,
			},
		};
	}
	const signedPayload = json.signedTransactionInfo ? decodeJwtPayloadUnsafe(json.signedTransactionInfo) : null;
	const productId = typeof signedPayload?.productId === "string" ? signedPayload.productId : (input.productId ?? null);
	const originalTransactionId = typeof signedPayload?.originalTransactionId === "string"
		? signedPayload.originalTransactionId
		: (input.originalTransactionId ?? input.transactionId);
	const expiresAt = numberToIso(signedPayload?.expiresDate ?? signedPayload?.expiresDateMs);
	const revokedAt = numberToIso(signedPayload?.revocationDate ?? signedPayload?.revocationDateMs);
	let status: EntitlementStatus = "active";
	if (revokedAt) status = "cancelled";
	if (expiresAt && Date.parse(expiresAt) <= Date.now()) status = "expired";
	pushDebugStage(stages, "resolved_apple_payload", {
		resolvedProductId: productId,
		resolvedOriginalTransactionId: originalTransactionId,
		expiresAt,
		revokedAt,
		status,
	});
	return {
		provider: "apple",
		state: "verified",
		code: "APPLE_VERIFIED",
		message: "Apple purchase verified.",
		productId,
		originalTransactionId,
		status,
		expiresAt,
		autoRenew: status === "active",
		verificationReference: input.transactionId,
		rawSummary: {
			stages,
			environment: input.environment,
			hasSignedTransactionInfo: !!json.signedTransactionInfo,
		},
	};
}

async function verifyGooglePurchase(env: Env, input: GoogleStoreEntitlementSyncInput): Promise<StoreVerificationResult> {
	const access = await getGoogleAccessToken(env);
	if (!access.ok || !access.token) {
		return {
			provider: "google",
			state: access.code === "GOOGLE_CONFIG_MISSING" ? "pending_validation" : "error",
			code: access.code,
			message: access.code === "GOOGLE_CONFIG_MISSING"
				? "Google verification credentials are not configured on backend."
				: "Google verification authentication failed.",
			productId: input.productId,
			originalTransactionId: input.orderId ?? input.purchaseToken,
			status: "inactive",
			expiresAt: null,
			autoRenew: false,
			verificationReference: input.purchaseToken,
			rawSummary: {},
		};
	}
	const endpoint = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(input.packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(input.purchaseToken)}`;
	const response = await fetch(endpoint, {
		headers: { Authorization: `Bearer ${access.token}` },
	});
	if (response.status === 404) {
		return {
			provider: "google",
			state: "invalid",
			code: "GOOGLE_PURCHASE_NOT_FOUND",
			message: "Google purchase token could not be verified.",
			productId: input.productId,
			originalTransactionId: input.orderId ?? input.purchaseToken,
			status: "inactive",
			expiresAt: null,
			autoRenew: false,
			verificationReference: input.purchaseToken,
			rawSummary: {},
		};
	}
	if (!response.ok) {
		return {
			provider: "google",
			state: "error",
			code: "GOOGLE_VERIFY_FAILED",
			message: "Google verification request failed.",
			productId: input.productId,
			originalTransactionId: input.orderId ?? input.purchaseToken,
			status: "inactive",
			expiresAt: null,
			autoRenew: false,
			verificationReference: input.purchaseToken,
			rawSummary: { httpStatus: response.status },
		};
	}
	const json = await response.json() as {
		subscriptionState?: string;
		latestOrderId?: string;
		lineItems?: Array<{ productId?: string; expiryTime?: string; autoRenewingPlan?: { autoRenewEnabled?: boolean } }>;
	};
	const lineItem = Array.isArray(json.lineItems) ? json.lineItems[0] : undefined;
	const productId = lineItem?.productId ?? input.productId;
	const expiresAt = typeof lineItem?.expiryTime === "string" ? lineItem.expiryTime : null;
	let status: EntitlementStatus = "inactive";
	if (json.subscriptionState === "SUBSCRIPTION_STATE_ACTIVE") status = "active";
	if (json.subscriptionState === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") status = "grace";
	if (json.subscriptionState === "SUBSCRIPTION_STATE_CANCELED") status = "cancelled";
	if (json.subscriptionState === "SUBSCRIPTION_STATE_EXPIRED") status = "expired";
	return {
		provider: "google",
		state: "verified",
		code: "GOOGLE_VERIFIED",
		message: "Google purchase verified.",
		productId,
		originalTransactionId: json.latestOrderId ?? input.orderId ?? input.purchaseToken,
		status,
		expiresAt,
		autoRenew: lineItem?.autoRenewingPlan?.autoRenewEnabled === true,
		verificationReference: input.purchaseToken,
		rawSummary: {
			subscriptionState: json.subscriptionState ?? null,
			latestOrderId: json.latestOrderId ?? null,
		},
	};
}

async function recordStoreVerificationAttempt(
	env: Env,
	input: {
		userId: string;
		provider: "apple" | "google";
		state: StoreVerificationState;
		code: string;
		transactionRef?: string | null;
		purchaseToken?: string | null;
		payload?: unknown;
		details?: Record<string, unknown>;
	},
) {
	await ensureEntitlementTables(env);
	const payloadRaw = input.payload ? JSON.stringify(input.payload) : null;
	await exec(
		env.DB,
		`INSERT INTO store_verification_attempts
		 (id, user_id, provider, outcome, code, transaction_hash, purchase_token_hash, payload_hash, details_json, created_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		randomId(),
		input.userId,
		input.provider,
		input.state,
		input.code,
		input.transactionRef ? await sha256Hex(input.transactionRef) : null,
		input.purchaseToken ? await sha256Hex(input.purchaseToken) : null,
		payloadRaw ? await sha256Hex(payloadRaw) : null,
		input.details ? JSON.stringify(input.details).slice(0, 4000) : null,
		nowIso(),
	);
}

export async function syncStoreEntitlement(
	env: Env,
	user: UserProfile,
	input: StoreEntitlementSyncInput,
): Promise<StoreSyncResponse> {
	const stages: string[] = [];
	pushDebugStage(stages, "parsed_payload", { provider: input.provider });

	const verification = input.provider === "apple"
		? await verifyApplePurchase(env, input)
		: await verifyGooglePurchase(env, input);
	pushDebugStage(stages, "verified_purchase", {
		state: verification.state,
		code: verification.code,
		productId: verification.productId,
	});

	let effectiveEntitlement: EntitlementRecord | null = null;
	let latestEntitlement: EntitlementRecord | null = null;
	let mappedPlanTier: PlanTier | null = null;
	try {
		effectiveEntitlement = await getEffectiveEntitlementForUser(env, user.id);
		latestEntitlement = await getLatestEntitlementForUser(env, user.id);
		pushDebugStage(stages, "loaded_existing_entitlement", {
			hasEffective: !!effectiveEntitlement,
			hasLatest: !!latestEntitlement,
		});
	} catch (error) {
		return buildStructuredSyncResponse({
			provider: verification.provider,
			verificationState: "error",
			code: "D1_READ_FAILED",
			message: "Backend could not read entitlement state from D1.",
			debugSummary: buildStoreSyncDebugSummary(env, input, verification, mappedPlanTier) + ` | stages=${stages.join(">")}` + ` | error=${errorDebugMessage(error)}`,
		});
	}

	if (verification.state === "verified") {
		const productId = verification.productId;
		if (!productId) {
			verification.state = "invalid";
			verification.code = "PRODUCT_ID_MISSING";
			verification.message = "Verified purchase missing product identifier.";
		} else if (verification.status !== "active" && verification.status !== "grace") {
			// A verified transaction that does not currently grant access should not be treated as sync success.
			verification.state = "invalid";
			verification.code = "ENTITLEMENT_STATUS_NOT_ACTIVE";
			verification.message = `Purchase verified but entitlement status is ${verification.status}, so access is not active.`;
			pushDebugStage(stages, "verified_but_inactive", { status: verification.status });
		} else {
			mappedPlanTier = resolveProductPlanTier(env, verification.provider, productId);
			pushDebugStage(stages, "resolved_plan", { productId, mappedPlanTier });
			if (!mappedPlanTier) {
				verification.state = "invalid";
				verification.code = "PRODUCT_NOT_MAPPED";
				verification.message = `Product ${productId} is not mapped to a backend plan. Check TAI_STORE_PRODUCT_PLAN_MAP.`;
			} else {
				try {
					const entitlement = await upsertUserEntitlement(env, {
						userId: user.id,
						planTier: mappedPlanTier,
						source: verification.provider,
						status: verification.status,
						startAt: nowIso(),
						expiresAt: verification.expiresAt,
						autoRenew: verification.autoRenew,
						externalProductId: productId,
						externalOriginalTransactionId: verification.originalTransactionId,
						lastValidatedAt: nowIso(),
						metadataJson: JSON.stringify({
							verificationState: verification.state,
							code: verification.code,
							reference: verification.verificationReference,
							rawSummary: verification.rawSummary,
						}),
					});
					pushDebugStage(stages, "wrote_entitlement", { entitlementId: entitlement?.id ?? null });
					if (!entitlement) {
						verification.state = "error";
						verification.code = "D1_WRITE_FAILED";
						verification.message = "Backend wrote entitlement but could not read it by ID.";
						pushDebugStage(stages, "write_readback_missing", { userId: user.id, productId });
					} else {
						latestEntitlement = entitlement;
						effectiveEntitlement = await getEffectiveEntitlementForUser(env, user.id);
						pushDebugStage(stages, "readback_effective_entitlement", {
							hasEffective: !!effectiveEntitlement,
							effectiveUserId: effectiveEntitlement?.userId ?? null,
							effectivePlanTier: effectiveEntitlement?.planTier ?? null,
							requiredPlanTier: mappedPlanTier,
						});

						if (!effectiveEntitlement) {
							verification.state = "error";
							verification.code = "ENTITLEMENT_READBACK_MISSING";
							verification.message = "Purchase verified and persisted, but no active entitlement is readable for this user.";
						} else if (effectiveEntitlement.userId !== user.id) {
							verification.state = "error";
							verification.code = "ENTITLEMENT_READBACK_USER_MISMATCH";
							verification.message = "Read-back entitlement user mismatch after sync.";
						} else if (PLAN_ORDER[effectiveEntitlement.planTier] < PLAN_ORDER[mappedPlanTier]) {
							verification.state = "error";
							verification.code = "ENTITLEMENT_READBACK_PLAN_MISMATCH";
							verification.message = `Read-back entitlement plan (${effectiveEntitlement.planTier}) is below expected mapped plan (${mappedPlanTier}).`;
						}
					}
				} catch (error) {
					verification.state = "error";
					verification.code = "D1_WRITE_FAILED";
					verification.message = "Backend could not write entitlement state to D1.";
					pushDebugStage(stages, "d1_write_failed", { error: errorDebugMessage(error) });
				}
			}
		}
	}

	try {
		await recordStoreVerificationAttempt(env, {
			userId: user.id,
			provider: verification.provider,
			state: verification.state,
			code: verification.code,
			transactionRef: verification.verificationReference,
			purchaseToken: input.provider === "google" ? input.purchaseToken : null,
			payload: input.rawPayload,
			details: {
				productId: verification.productId,
				status: verification.status,
				expiresAt: verification.expiresAt,
				rawSummary: verification.rawSummary,
			},
		});
		pushDebugStage(stages, "recorded_attempt");
	} catch (error) {
		pushDebugStage(stages, "record_attempt_failed", { error: errorDebugMessage(error) });
	}

	try {
		await logAudit(env, user, "entitlement.store_sync", "user", user.id, {
			provider: verification.provider,
			verificationState: verification.state,
			code: verification.code,
			productId: verification.productId,
		});
		pushDebugStage(stages, "wrote_audit_log");
	} catch (error) {
		pushDebugStage(stages, "audit_log_failed", { error: errorDebugMessage(error) });
	}

	const debugSummary = buildStoreSyncDebugSummary(env, input, verification, mappedPlanTier);
	return buildStructuredSyncResponse({
		provider: verification.provider,
		verificationState: verification.state,
		code: verification.code,
		message: verification.message,
		entitlement: effectiveEntitlement,
		latestEntitlement,
		debugSummary: [debugSummary, `stages=${stages.join(">")}`].filter(Boolean).join(" | "),
	});
}

export async function removeUser(env: Env, actor: UserProfile, userId: string) {
	await exec(env.DB, "UPDATE users SET status = 'DELETED', updated_at = ? WHERE id = ?", nowIso(), userId);
	await logAudit(env, actor, "user.delete", "user", userId, null);
	return true;
}

export async function getUserPermissions(env: Env, actor: UserProfile, userId: string) {
	await syncModelsIfNeeded(env);
	const assignedRows = await queryAll<{ model_id: string }>(env.DB, "SELECT model_id FROM user_permissions WHERE user_id = ?", userId);
	const assigned = new Set(assignedRows.map((row) => row.model_id));
	const models = await queryAll<ModelRow>(
		env.DB,
		"SELECT id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at FROM models ORDER BY name ASC",
	);
	return models.map((row) => ({ ...mapModel(row), canAccess: assigned.has(row.id) }));
}

export async function saveUserPermissions(env: Env, actor: UserProfile, userId: string, modelIds: string[]) {
	await exec(env.DB, "DELETE FROM user_permissions WHERE user_id = ?", userId);
	for (const modelId of modelIds) {
		await exec(env.DB, "INSERT INTO user_permissions (user_id, model_id, created_at) VALUES (?, ?, ?)", userId, modelId, nowIso());
	}
	await logAudit(env, actor, "user.permissions", "user", userId, { modelIds });
	return true;
}

export async function listAdminModels(env: Env) {
	await syncModelsIfNeeded(env);
	const rows = await queryAll<ModelRow>(
		env.DB,
		"SELECT id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at FROM models ORDER BY name ASC",
	);
	return rows.map(mapModel);
}

export async function patchAdminModel(env: Env, actor: UserProfile, modelId: string, input: z.infer<typeof adminModelPatchSchema>) {
	const current = await queryFirst<ModelRow>(
		env.DB,
		"SELECT id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at FROM models WHERE id = ? LIMIT 1",
		modelId,
	);
	if (!current) return null;
	await exec(
		env.DB,
		"UPDATE models SET name = ?, is_enabled = ?, updated_at = ? WHERE id = ?",
		input.displayName ?? current.name,
		typeof input.enabled === "boolean" ? (input.enabled ? 1 : 0) : current.is_enabled,
		nowIso(),
		modelId,
	);
	await logAudit(env, actor, "model.update", "model", modelId, input);
	const updated = await queryFirst<ModelRow>(
		env.DB,
		"SELECT id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at FROM models WHERE id = ? LIMIT 1",
		modelId,
	);
	return updated ? mapModel(updated) : null;
}

export async function createAdminModel(env: Env, actor: UserProfile, input: z.infer<typeof adminModelPostSchema>) {
	const id = input.slug ? `manual-${input.slug}` : randomId();
	const createdAt = nowIso();
	await exec(
		env.DB,
		"INSERT INTO models (id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)",
		id,
		input.providerModelId ?? id,
		input.displayName ?? input.providerModelId ?? id,
		"openrouter",
		modelLogo("openrouter"),
		null,
		JSON.stringify(["streaming"]),
		null,
		"paid",
		input.enabled === false ? 0 : 1,
		createdAt,
		createdAt,
	);
	await logAudit(env, actor, "model.create", "model", id, input);
	const created = await queryFirst<ModelRow>(
		env.DB,
		"SELECT id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at FROM models WHERE id = ? LIMIT 1",
		id,
	);
	return created ? mapModel(created) : null;
}

export async function listAdminProviders(env: Env) {
	const models = await queryAll<ModelRow>(env.DB, "SELECT id, name, is_enabled FROM models ORDER BY name ASC");
	return [{
		...PROVIDER,
		models: models.slice(0, 50).map((model) => ({ id: model.id, displayName: model.name, enabled: boolFrom(model.is_enabled) })),
		secrets: [
			{ id: "openrouter-api-key", kind: "api_key", updatedAt: nowIso() },
		],
	}] satisfies ProviderRecord[];
}

export async function listAdminChats(env: Env) {
	const rows = await queryAll<D1Row>(
		env.DB,
		`SELECT c.id, c.title, c.is_deleted, c.updated_at, u.email, u.username, u.display_name
		 FROM chats c
		 JOIN users u ON u.id = c.user_id
		 ORDER BY c.updated_at DESC
		 LIMIT 100`,
	);
	const ids = rows.map((row) => String(row.id));
	const messages = await getMessagesByChatIds(env, ids);
	return rows.map((row) => ({
		id: String(row.id),
		title: String(row.title),
		isDeleted: boolFrom(row.is_deleted),
		updatedAt: String(row.updated_at),
		user: {
			email: String(row.email),
			username: String(row.username),
			displayName: row.display_name ? String(row.display_name) : null,
		},
		messages: (messages.get(String(row.id)) ?? []).map((message) => ({
			id: message.id,
			role: message.role,
			content: message.content,
			isDeleted: message.isDeleted,
		})),
	}));
}

export async function logAudit(env: Env, actor: UserProfile | null, action: string, targetType: string, targetId: string | null, metadata: unknown) {
	await exec(
		env.DB,
		"INSERT INTO admin_audit_log (id, actor_user_id, action, target_type, target_id, metadata_json, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
		randomId(),
		actor?.id ?? null,
		action,
		targetType,
		targetId,
		metadata == null ? null : JSON.stringify(metadata),
		nowIso(),
	);
}

export async function listAudit(env: Env) {
	return queryAll<D1Row>(
		env.DB,
		`SELECT a.id, a.action, a.target_type, a.target_id, a.created_at, u.email as actor_email, u.username as actor_username, u.display_name as actor_display_name
		 FROM admin_audit_log a
		 LEFT JOIN users u ON u.id = a.actor_user_id
		 ORDER BY a.created_at DESC
		 LIMIT 100`,
	);
}

export async function getAccessibleModelById(user: UserProfile, env: Env, modelId: string) {
	const models = await getAccessibleModels(user, env);
	const model = models.find((entry) => entry.id === modelId || entry.providerModelId === modelId) ?? null;
	if (!model) return null;
	return model;
}

function planDailyTokenLimit(env: Env, tier: PlanTier) {
	switch (tier) {
		case "starter":
			return envInt(env, "TAI_DAILY_TOKENS_STARTER", PLAN_DAILY_TOKENS_DEFAULT.starter, 1000, 5000000);
		case "pro":
			return envInt(env, "TAI_DAILY_TOKENS_PRO", PLAN_DAILY_TOKENS_DEFAULT.pro, 1000, 10000000);
		case "power":
			return envInt(env, "TAI_DAILY_TOKENS_POWER", PLAN_DAILY_TOKENS_DEFAULT.power, 1000, 20000000);
		default:
			return envInt(env, "TAI_DAILY_TOKENS_FREE", PLAN_DAILY_TOKENS_DEFAULT.free, 1000, 1000000);
	}
}

function planDailyCostUnitsLimit(env: Env, tier: PlanTier) {
	switch (tier) {
		case "starter":
			return envInt(env, "TAI_DAILY_COST_UNITS_STARTER", PLAN_DAILY_COST_UNITS_DEFAULT.starter, 100, 5000000);
		case "pro":
			return envInt(env, "TAI_DAILY_COST_UNITS_PRO", PLAN_DAILY_COST_UNITS_DEFAULT.pro, 100, 10000000);
		case "power":
			return envInt(env, "TAI_DAILY_COST_UNITS_POWER", PLAN_DAILY_COST_UNITS_DEFAULT.power, 100, 20000000);
		default:
			return envInt(env, "TAI_DAILY_COST_UNITS_FREE", PLAN_DAILY_COST_UNITS_DEFAULT.free, 100, 1000000);
	}
}

export function planRequestTokenLimit(env: Env, tier: PlanTier) {
	switch (tier) {
		case "starter":
			return envInt(env, "TAI_REQUEST_TOKENS_STARTER", PLAN_REQUEST_TOKENS_DEFAULT.starter, 256, 32768);
		case "pro":
			return envInt(env, "TAI_REQUEST_TOKENS_PRO", PLAN_REQUEST_TOKENS_DEFAULT.pro, 256, 65536);
		case "power":
			return envInt(env, "TAI_REQUEST_TOKENS_POWER", PLAN_REQUEST_TOKENS_DEFAULT.power, 256, 65536);
		default:
			return envInt(env, "TAI_REQUEST_TOKENS_FREE", PLAN_REQUEST_TOKENS_DEFAULT.free, 256, 16384);
	}
}

function streamConcurrencyLimit(env: Env, tier: PlanTier) {
	switch (tier) {
		case "starter":
			return envInt(env, "TAI_STREAM_CONCURRENCY_STARTER", PLAN_STREAM_CONCURRENCY_DEFAULT.starter, 1, 12);
		case "pro":
			return envInt(env, "TAI_STREAM_CONCURRENCY_PRO", PLAN_STREAM_CONCURRENCY_DEFAULT.pro, 1, 16);
		case "power":
			return envInt(env, "TAI_STREAM_CONCURRENCY_POWER", PLAN_STREAM_CONCURRENCY_DEFAULT.power, 1, 20);
		default:
			return envInt(env, "TAI_STREAM_CONCURRENCY_FREE", PLAN_STREAM_CONCURRENCY_DEFAULT.free, 1, 8);
	}
}

function modelCostMultiplier(model: Pick<ModelRecord, "category">) {
	switch (model.category) {
		case "free-basic":
			return 1;
		case "fast-everyday":
			return 2;
		case "image-vision":
			return 3;
		case "premium-reasoning":
			return 6;
		case "premium-creative":
			return 7;
		case "image-generation":
			return 8;
		default:
			return 10;
	}
}

export function estimateTokensForMessages(messages: Array<{
	role: "system" | "user" | "assistant";
	content: string | Array<{ type: "text"; text: string } | { type: "image_url"; image_url: { url: string } }>;
}>) {
	let chars = 0;
	for (const message of messages) {
		if (typeof message.content === "string") {
			chars += message.content.length;
			continue;
		}
		for (const part of message.content) {
			if (part.type === "text") chars += part.text.length;
			if (part.type === "image_url") chars += 220;
		}
	}
	const estimated = Math.ceil(chars / 4) + messages.length * 8;
	return Math.max(1, estimated);
}

export function estimateCostUnits(model: Pick<ModelRecord, "category">, estimatedTotalTokens: number) {
	const base = Math.max(1, Math.ceil(estimatedTotalTokens / 100));
	return base * modelCostMultiplier(model);
}

export function applyRequestTokenGuard(env: Env, planTier: PlanTier, estimatedInputTokens: number, requestedOutputTokens: number) {
	const allowance = planRequestTokenLimit(env, planTier);
	const estimatedTotal = estimatedInputTokens + requestedOutputTokens;
	if (estimatedTotal <= allowance) {
		return {
			allowed: true as const,
			allowance,
			estimatedTotal,
			resolvedMaxTokens: requestedOutputTokens,
			guardApplied: false,
		};
	}
	const remainingOutput = allowance - estimatedInputTokens;
	if (remainingOutput >= 128) {
		return {
			allowed: true as const,
			allowance,
			estimatedTotal,
			resolvedMaxTokens: remainingOutput,
			guardApplied: true,
		};
	}
	return {
		allowed: false as const,
		allowance,
		estimatedTotal,
		resolvedMaxTokens: 0,
		guardApplied: true,
		code: "REQUEST_TOKEN_LIMIT_EXCEEDED",
		message: "Estimated request size exceeds your plan allowance.",
	};
}

async function usageWindowSnapshot(env: Env, sinceIso: string, userId?: string | null) {
	const whereUser = userId ? "AND user_id = ?" : "";
	const row = await queryFirst<{ requests: number; totalTokens: number; totalCostUnits: number }>(
		env.DB,
		`SELECT COUNT(*) AS requests,
		        COALESCE(SUM(estimated_total_tokens), 0) AS totalTokens,
		        COALESCE(SUM(estimated_cost_units), 0) AS totalCostUnits
		 FROM usage_ledger
		 WHERE created_at >= ?
		   AND status IN ('started', 'completed', 'truncated', 'upstream_error', 'client_error')
		   ${whereUser}`,
		sinceIso,
		...(userId ? [userId] : []),
	);
	return {
		requests: Number(row?.requests ?? 0),
		totalEstimatedTokens: Number(row?.totalTokens ?? 0),
		totalEstimatedCostUnits: Number(row?.totalCostUnits ?? 0),
	};
}

export async function checkRollingUsageBudget(
	env: Env,
	input: { userId: string; planTier: PlanTier; projectedTokens: number; projectedCostUnits: number },
): Promise<RollingUsageDecision> {
	await ensureSecurityTables(env);
	const now = Date.now();
	const tier = input.planTier;

	// Check 2 windows: 24-hour daily, 4-week (672 hours) rolling
	const windows = [
		{ hours: 24, tokenLimit: planDailyTokenLimit(env, tier), costLimit: planDailyCostUnitsLimit(env, tier), code: "DAILY_LIMIT", label: "daily" },
		{ hours: 672, tokenLimit: PLAN_WEEKLY_TOKENS[tier], costLimit: PLAN_WEEKLY_COST_UNITS[tier], code: "MONTHLY_LIMIT", label: "4-week" },
	];

	for (const window of windows) {
		const sinceIso = new Date(now - window.hours * 60 * 60 * 1000).toISOString();
		const current = await usageWindowSnapshot(env, sinceIso, input.userId);
		const nextTokens = current.totalEstimatedTokens + input.projectedTokens;
		const nextCost = current.totalEstimatedCostUnits + input.projectedCostUnits;

		if (nextTokens > window.tokenLimit) {
			return {
				limited: true,
				code: `ROLLING_${window.code}_TOKEN` as any,
				message: `Your ${window.label} token limit has been reached. Please wait or upgrade your plan.`,
				requests: current.requests,
				totalEstimatedTokens: current.totalEstimatedTokens,
				totalEstimatedCostUnits: current.totalEstimatedCostUnits,
			};
		}
		if (nextCost > window.costLimit) {
			return {
				limited: true,
				code: `ROLLING_${window.code}_COST` as any,
				message: `Your ${window.label} usage limit has been reached. Please wait or upgrade your plan.`,
				requests: current.requests,
				totalEstimatedTokens: current.totalEstimatedTokens,
				totalEstimatedCostUnits: current.totalEstimatedCostUnits,
			};
		}
	}
	// All windows passed — get daily snapshot for the return
	const dailySince = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
	const dailyCurrent = await usageWindowSnapshot(env, dailySince, input.userId);
	return {
		limited: false,
		requests: dailyCurrent.requests,
		totalEstimatedTokens: dailyCurrent.totalEstimatedTokens,
		totalEstimatedCostUnits: dailyCurrent.totalEstimatedCostUnits,
	};
}

export async function getUserUsageSnapshot(env: Env, userId: string, planTier: PlanTier) {
	await ensureSecurityTables(env);
	const now = Date.now();

	// 24-hour daily window
	const since24h = new Date(now - 24 * 60 * 60 * 1000).toISOString();
	const daily = await usageWindowSnapshot(env, since24h, userId);

	// 4-week (28-day) rolling window
	const since28d = new Date(now - 672 * 60 * 60 * 1000).toISOString();
	const monthly = await usageWindowSnapshot(env, since28d, userId);

	const isFree = planTier === "free";

	return {
		planTier,
		// 24-hour daily
		tokensUsed: daily.totalEstimatedTokens,
		tokenLimit: isFree ? -1 : planDailyTokenLimit(env, planTier),
		costUnitsUsed: daily.totalEstimatedCostUnits,
		costUnitLimit: isFree ? -1 : planDailyCostUnitsLimit(env, planTier),
		resetAt: new Date(now + 24 * 60 * 60 * 1000).toISOString(),
		// 4-week rolling
		weeklyTokensUsed: monthly.totalEstimatedTokens,
		weeklyTokenLimit: isFree ? -1 : PLAN_WEEKLY_TOKENS[planTier],
		weeklyCostUsed: monthly.totalEstimatedCostUnits,
		weeklyCostLimit: isFree ? -1 : PLAN_WEEKLY_COST_UNITS[planTier],
		weeklyResetAt: new Date(now + 672 * 60 * 60 * 1000).toISOString(),
		// General
		requestCount: daily.requests,
		windowHours: 24,
	};
}

export async function checkGlobalSpendCircuit(env: Env, projectedCostUnits: number): Promise<GlobalSpendDecision> {
	await ensureSecurityTables(env);
	const windowHours = envInt(env, "TAI_GLOBAL_SPEND_WINDOW_HOURS", 24, 1, 168);
	const sinceIso = new Date(Date.now() - windowHours * 60 * 60 * 1000).toISOString();
	const snapshot = await usageWindowSnapshot(env, sinceIso, null);
	const globalLimit = envInt(env, "TAI_GLOBAL_DAILY_COST_UNITS_LIMIT", 4000000, 1000, 100000000);
	if (snapshot.totalEstimatedCostUnits + projectedCostUnits > globalLimit) {
		return {
			limited: true,
			code: "GLOBAL_SPEND_CIRCUIT_OPEN",
			message: "Temporary capacity protection is active. Please retry shortly.",
			totalEstimatedCostUnits: snapshot.totalEstimatedCostUnits,
			limit: globalLimit,
		};
	}
	return {
		limited: false,
		totalEstimatedCostUnits: snapshot.totalEstimatedCostUnits,
		limit: globalLimit,
	};
}

export async function acquireStreamLease(env: Env, userId: string, planTier: PlanTier): Promise<StreamConcurrencyDecision> {
	await ensureSecurityTables(env);
	const now = nowIso();
	await exec(env.DB, "DELETE FROM active_streams WHERE expires_at <= ?", now);
	const row = await queryFirst<{ active: number }>(
		env.DB,
		"SELECT COUNT(*) AS active FROM active_streams WHERE user_id = ? AND expires_at > ?",
		userId,
		now,
	);
	const active = Number(row?.active ?? 0);
	const limit = streamConcurrencyLimit(env, planTier);
	if (active >= limit) {
		return {
			limited: true,
			code: "CONCURRENT_STREAM_LIMIT",
			message: "Too many active generations for this account.",
			leaseId: null,
			active,
			limit,
		};
	}
	const leaseSec = envInt(env, "TAI_STREAM_LEASE_SECONDS", 900, 30, 3600);
	const leaseId = randomId();
	const expiresAt = new Date(Date.now() + leaseSec * 1000).toISOString();
	await exec(
		env.DB,
		"INSERT INTO active_streams (lease_id, user_id, created_at, expires_at, updated_at) VALUES (?, ?, ?, ?, ?)",
		leaseId,
		userId,
		now,
		expiresAt,
		now,
	);
	return {
		limited: false,
		leaseId,
		active: active + 1,
		limit,
	};
}

export async function releaseStreamLease(env: Env, leaseId: string | null | undefined) {
	if (!leaseId) return;
	await ensureSecurityTables(env);
	await exec(env.DB, "DELETE FROM active_streams WHERE lease_id = ?", leaseId);
}

export async function recordStreamLedgerStart(env: Env, input: StreamLedgerStartInput) {
	await ensureSecurityTables(env);
	const now = nowIso();
	await exec(
		env.DB,
		`INSERT INTO usage_ledger
		 (request_id, user_id, model_id, endpoint, plan_tier, estimated_input_tokens, reserved_output_tokens, estimated_total_tokens, estimated_cost_units, actual_output_chars, status, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)`,
		input.requestId,
		input.userId,
		input.modelId,
		input.endpoint,
		input.planTier,
		input.estimatedInputTokens,
		input.reservedOutputTokens,
		input.estimatedTotalTokens,
		input.estimatedCostUnits,
		input.status,
		now,
		now,
	);
}

export async function recordStreamLedgerFinalize(env: Env, input: StreamLedgerFinalizeInput) {
	await ensureSecurityTables(env);
	await exec(
		env.DB,
		"UPDATE usage_ledger SET status = ?, actual_output_chars = ?, updated_at = ? WHERE request_id = ?",
		input.status,
		input.actualOutputChars,
		nowIso(),
		input.requestId,
	);
}

export function sseEvent(event: string, data: unknown) {
	return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

export async function streamOpenRouter(
	env: Env,
	model: string,
	messages: Array<{
		role: "system" | "user" | "assistant";
		content:
		| string
		| Array<{ type: "text"; text: string } | { type: "image_url"; image_url: { url: string } }>;
	}>,
	maxTokens?: number,
) {
	const headers = new Headers({
		"Content-Type": "application/json",
		Accept: "text/event-stream",
		"HTTP-Referer": "https://ai.gravitilabs.com",
		"X-Title": "TABAI",
	});
	if (env.OPENROUTER_API_KEY) headers.set("Authorization", `Bearer ${env.OPENROUTER_API_KEY}`);
	return fetch("https://openrouter.ai/api/v1/chat/completions", {
		method: "POST",
		headers,
		body: JSON.stringify({
			model,
			stream: true,
			messages,
			max_tokens: maxTokens ?? 1024,
		}),
	});
}

// ══════════════════════════════════════════════════════════════════
// ADMIN ANALYTICS & ENHANCED FUNCTIONS
// ══════════════════════════════════════════════════════════════════

export async function getAdminOverviewStats(env: Env) {
	const [userStats, chatStats, entitlementStats, usageStats] = await Promise.all([
		queryFirst<{ total: number; active_24h: number; active_7d: number; active_30d: number; frozen: number }>(
			env.DB,
			`SELECT
				COUNT(*) as total,
				SUM(CASE WHEN last_active_at > datetime('now', '-1 day') THEN 1 ELSE 0 END) as active_24h,
				SUM(CASE WHEN last_active_at > datetime('now', '-7 days') THEN 1 ELSE 0 END) as active_7d,
				SUM(CASE WHEN last_active_at > datetime('now', '-30 days') THEN 1 ELSE 0 END) as active_30d,
				SUM(CASE WHEN status = 'FROZEN' THEN 1 ELSE 0 END) as frozen
			FROM users WHERE status != 'DELETED'`,
		),
		queryFirst<{ total: number; today: number }>(
			env.DB,
			`SELECT COUNT(*) as total, SUM(CASE WHEN created_at > datetime('now', '-1 day') THEN 1 ELSE 0 END) as today FROM chats WHERE is_deleted = 0`,
		),
		queryAll<{ plan_tier: string; source: string; cnt: number }>(
			env.DB,
			`SELECT plan_tier, source, COUNT(*) as cnt FROM user_entitlements WHERE status = 'active' GROUP BY plan_tier, source`,
		),
		queryFirst<{ requests_24h: number; requests_7d: number }>(
			env.DB,
			`SELECT
				SUM(CASE WHEN created_at > datetime('now', '-1 day') THEN 1 ELSE 0 END) as requests_24h,
				SUM(CASE WHEN created_at > datetime('now', '-7 days') THEN 1 ELSE 0 END) as requests_7d
			FROM usage_events`,
		),
	]);

	const tierBreakdown: Record<string, number> = {};
	const sourceBreakdown: Record<string, number> = {};
	for (const row of entitlementStats) {
		tierBreakdown[row.plan_tier] = (tierBreakdown[row.plan_tier] ?? 0) + row.cnt;
		sourceBreakdown[row.source] = (sourceBreakdown[row.source] ?? 0) + row.cnt;
	}

	return {
		users: { total: userStats?.total ?? 0, active24h: userStats?.active_24h ?? 0, active7d: userStats?.active_7d ?? 0, active30d: userStats?.active_30d ?? 0, frozen: userStats?.frozen ?? 0 },
		chats: { total: chatStats?.total ?? 0, today: chatStats?.today ?? 0 },
		subscriptions: { tierBreakdown, sourceBreakdown, totalPaid: Object.values(tierBreakdown).reduce((s, v) => s + v, 0) - (tierBreakdown["free"] ?? 0) },
		usage: { requests24h: usageStats?.requests_24h ?? 0, requests7d: usageStats?.requests_7d ?? 0 },
	};
}

export async function getAdminUserGrowth(env: Env, days = 30) {
	return queryAll<{ day: string; signups: number; cumulative: number }>(
		env.DB,
		`SELECT DATE(created_at) as day, COUNT(*) as signups, 0 as cumulative FROM users WHERE created_at > datetime('now', '-${days} days') AND status != 'DELETED' GROUP BY day ORDER BY day`,
	);
}

export async function getAdminModelUsage(env: Env, days = 7) {
	return queryAll<{ model_id: string; requests: number; total_output: number; errors: number }>(
		env.DB,
		`SELECT model_id, COUNT(*) as requests, COALESCE(SUM(output_chars), 0) as total_output, SUM(CASE WHEN status != 'completed' THEN 1 ELSE 0 END) as errors FROM usage_events WHERE created_at > datetime('now', '-${days} days') GROUP BY model_id ORDER BY requests DESC LIMIT 50`,
	);
}

export async function getAdminRevenueBreakdown(env: Env) {
	return queryAll<{ plan_tier: string; source: string; cnt: number }>(
		env.DB,
		`SELECT plan_tier, source, COUNT(*) as cnt FROM user_entitlements WHERE status IN ('active', 'grace') GROUP BY plan_tier, source ORDER BY cnt DESC`,
	);
}

export async function getAdminSafetyEvents(env: Env, limit = 100, offset = 0) {
	return queryAll<D1Row>(
		env.DB,
		`SELECT id, event_type, user_id, model_id, code, message, created_at FROM safety_events ORDER BY created_at DESC LIMIT ? OFFSET ?`,
		limit, offset,
	);
}

export async function getAdminErrorSummary(env: Env, days = 7) {
	return queryAll<{ event_type: string; model_id: string; cnt: number }>(
		env.DB,
		`SELECT event_type, COALESCE(model_id, 'unknown') as model_id, COUNT(*) as cnt FROM safety_events WHERE created_at > datetime('now', '-${days} days') GROUP BY event_type, model_id ORDER BY cnt DESC LIMIT 50`,
	);
}

export async function getAdminUserChats(env: Env, userId: string) {
	return queryAll<D1Row>(
		env.DB,
		`SELECT c.id, c.title, c.model_id, c.is_pinned, c.is_deleted, c.created_at, c.updated_at,
			(SELECT COUNT(*) FROM messages m WHERE m.chat_id = c.id AND m.is_deleted = 0) as message_count
		FROM chats c WHERE c.user_id = ? ORDER BY c.updated_at DESC LIMIT 50`,
		userId,
	);
}

// Admin notes
export async function listAdminNotes(env: Env, userId: string) {
	return queryAll<D1Row>(
		env.DB,
		`SELECT n.id, n.content, n.created_at, u.email as author_email, u.username as author_username
		FROM admin_notes n LEFT JOIN users u ON u.id = n.author_id
		WHERE n.user_id = ? ORDER BY n.created_at DESC LIMIT 50`,
		userId,
	);
}

export async function createAdminNote(env: Env, userId: string, authorId: string, content: string) {
	const id = randomId();
	await exec(env.DB, "INSERT INTO admin_notes (id, user_id, author_id, content, created_at) VALUES (?, ?, ?, ?, ?)", id, userId, authorId, content, nowIso());
	return { id };
}

// Discount codes
export async function listDiscountCodes(env: Env) {
	return queryAll<D1Row>(env.DB, "SELECT * FROM discount_codes ORDER BY created_at DESC");
}

export async function createDiscountCode(env: Env, input: { code: string; planTier: PlanTier; durationDays: number; maxUses: number; expiresAt?: string }, createdBy: string) {
	const id = randomId();
	await exec(env.DB,
		"INSERT INTO discount_codes (id, code, plan_tier, duration_days, max_uses, current_uses, is_active, created_by, created_at, expires_at) VALUES (?, ?, ?, ?, ?, 0, 1, ?, ?, ?)",
		id, input.code.toUpperCase(), input.planTier, input.durationDays, input.maxUses, createdBy, nowIso(), input.expiresAt ?? null,
	);
	return { id, code: input.code.toUpperCase() };
}

export async function deleteDiscountCode(env: Env, codeId: string) {
	await exec(env.DB, "UPDATE discount_codes SET is_active = 0 WHERE id = ?", codeId);
}

export async function redeemDiscountCode(env: Env, user: UserProfile, code: string) {
	const dc = await queryFirst<D1Row>(env.DB, "SELECT * FROM discount_codes WHERE code = ? COLLATE NOCASE AND is_active = 1", code);
	if (!dc) return { error: "Invalid or expired code" };
	if (dc.current_uses >= dc.max_uses) return { error: "Code has been fully redeemed" };
	if (dc.expires_at && new Date(dc.expires_at as string) < new Date()) return { error: "Code has expired" };

	const already = await queryFirst<D1Row>(env.DB, "SELECT id FROM discount_redemptions WHERE code_id = ? AND user_id = ?", dc.id, user.id);
	if (already) return { error: "You have already redeemed this code" };

	const redemptionId = randomId();
	const entitlementId = randomId();
	const now = nowIso();
	const expiresAt = new Date(Date.now() + (dc.duration_days as number) * 86400000).toISOString();

	await exec(env.DB, "INSERT INTO discount_redemptions (id, code_id, user_id, redeemed_at) VALUES (?, ?, ?, ?)", redemptionId, dc.id, user.id, now);
	await exec(env.DB, "UPDATE discount_codes SET current_uses = current_uses + 1 WHERE id = ?", dc.id);
	await exec(env.DB,
		`INSERT INTO user_entitlements (id, user_id, plan_tier, source, status, start_at, expires_at, auto_renew, created_at, updated_at)
		VALUES (?, ?, ?, 'admin', 'active', ?, ?, 0, ?, ?)`,
		entitlementId, user.id, dc.plan_tier, now, expiresAt, now, now,
	);

	return { success: true, planTier: dc.plan_tier, expiresAt };
}

// Enhanced user listing with pagination and search
export async function listUsersPaginated(env: Env, options: { search?: string; planTier?: string; status?: string; page?: number; limit?: number }) {
	const page = options.page ?? 1;
	const limit = Math.min(options.limit ?? 50, 200);
	const offset = (page - 1) * limit;
	const conditions: string[] = ["status != 'DELETED'"];
	const params: unknown[] = [];

	if (options.search) {
		conditions.push("(email LIKE ? OR username LIKE ? OR display_name LIKE ? OR id LIKE ?)");
		const q = `%${options.search}%`;
		params.push(q, q, q, q);
	}
	if (options.status) { conditions.push("status = ?"); params.push(options.status); }

	const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
	const countResult = await queryFirst<{ cnt: number }>(env.DB, `SELECT COUNT(*) as cnt FROM users ${where}`, ...params);
	const total = countResult?.cnt ?? 0;

	const rows = await queryAll<any>(env.DB,
		`SELECT id, email, username, display_name, role, status, plan_tier, email_verified_at, last_active_at, created_at, updated_at, signup_platform
		FROM users ${where} ORDER BY created_at DESC LIMIT ? OFFSET ?`,
		...params, limit, offset,
	);

	const userIds = rows.map((r: any) => r.id);
	const entitlements = userIds.length > 0 ? await getEffectiveEntitlementsByUserIds(env, userIds) : new Map();
	const users = rows.map((row: any) => ({ ...mapUser(row, entitlements.get(row.id) ?? null), signupPlatform: row.signup_platform ?? "web" }));

	// Filter by effective plan tier if requested
	const filtered = options.planTier ? users.filter((u: any) => u.planTier === options.planTier) : users;

	return { users: filtered, total, page, limit, totalPages: Math.ceil(total / limit) };
}

// System health
export async function getSystemHealth(env: Env) {
	const [users, chats, messages, models, events, safety] = await Promise.all([
		queryFirst<{ cnt: number }>(env.DB, "SELECT COUNT(*) as cnt FROM users WHERE status != 'DELETED'"),
		queryFirst<{ cnt: number }>(env.DB, "SELECT COUNT(*) as cnt FROM chats WHERE is_deleted = 0"),
		queryFirst<{ cnt: number }>(env.DB, "SELECT COUNT(*) as cnt FROM messages WHERE is_deleted = 0"),
		queryFirst<{ cnt: number }>(env.DB, "SELECT COUNT(*) as cnt FROM models WHERE is_enabled = 1"),
		queryFirst<{ cnt: number }>(env.DB, "SELECT COUNT(*) as cnt FROM usage_events"),
		queryFirst<{ cnt: number; recent: number }>(env.DB, "SELECT COUNT(*) as cnt, SUM(CASE WHEN created_at > datetime('now', '-1 hour') THEN 1 ELSE 0 END) as recent FROM safety_events"),
	]);
	return {
		tables: { users: users?.cnt ?? 0, chats: chats?.cnt ?? 0, messages: messages?.cnt ?? 0, models: models?.cnt ?? 0, usageEvents: events?.cnt ?? 0, safetyEvents: safety?.cnt ?? 0 },
		recentSafetyEvents: safety?.recent ?? 0,
	};
}

// ══════════════════════════════════════════════════════════════════
// FAL.AI IMAGE & VIDEO GENERATION
// ══════════════════════════════════════════════════════════════════

export type GenerationType = "image" | "video" | "image_to_video";
export type GenerationStatus = "queued" | "processing" | "completed" | "failed" | "cancelled";

export type GenerationRecord = {
	id: string;
	userId: string;
	chatId: string | null;
	falRequestId: string;
	provider: string;
	modelId: string;
	modelDisplayName: string | null;
	generationType: GenerationType;
	status: GenerationStatus;
	prompt: string;
	negativePrompt: string | null;
	parameters: string | null;
	resultUrl: string | null;
	resultMetadata: string | null;
	estimatedCostUnits: number;
	actualCostUnits: number | null;
	errorMessage: string | null;
	createdAt: string;
	completedAt: string | null;
};

const FAL_MODEL_MAP: Record<string, { displayName: string; generationType: GenerationType; minTier: PlanTier; costUnits: number }> = {
	"fal-ai/flux/schnell":                                         { displayName: "TABAI Image Fast",  generationType: "image",          minTier: "starter", costUnits: 30 },
	"fal-ai/flux/dev":                                             { displayName: "TABAI Image",       generationType: "image",          minTier: "pro",     costUnits: 250 },
	"fal-ai/flux-2-pro":                                           { displayName: "TABAI Image Pro",   generationType: "image",          minTier: "pro",     costUnits: 300 },
	"fal-ai/flux-2-pro-ultra":                                     { displayName: "TABAI Image Ultra", generationType: "image",          minTier: "power",   costUnits: 700 },
	"fal-ai/flux-lora":                                            { displayName: "FLUX.1 LoRA",       generationType: "image",          minTier: "power",   costUnits: 350 },
	"fal-ai/kling-video/v2.5/master/text-to-video":                { displayName: "TABAI Video",       generationType: "video",          minTier: "pro",     costUnits: 11200 },
	"fal-ai/veo3":                                                 { displayName: "TABAI Video Pro",   generationType: "video",          minTier: "power",   costUnits: 10000 },
	"fal-ai/sora-2-pro":                                           { displayName: "TABAI Video Ultra", generationType: "video",          minTier: "power",   costUnits: 25000 },
	"fal-ai/kling-video/v2.5/master/image-to-video":               { displayName: "Animate Photo",     generationType: "image_to_video", minTier: "pro",     costUnits: 11200 },
};

const TIER_ORDER: Record<PlanTier, number> = { free: 0, starter: 1, pro: 2, power: 3 };

export const falGenerateImageSchema = z.object({
	prompt: z.string().min(1).max(2000),
	negativePrompt: z.string().max(1000).optional(),
	modelId: z.string().min(1),
	chatId: z.string().optional(),
	imageSize: z.enum(["square_hd", "square", "landscape_4_3", "landscape_16_9", "portrait_4_3", "portrait_16_9"]).optional(),
	numImages: z.number().int().min(1).max(4).optional(),
	style: z.string().optional(),
});

export const falGenerateVideoSchema = z.object({
	prompt: z.string().min(1).max(2000),
	negativePrompt: z.string().max(1000).optional(),
	modelId: z.string().min(1),
	chatId: z.string().optional(),
	duration: z.enum(["3", "5", "10"]).optional(),
	resolution: z.enum(["720p", "1080p"]).optional(),
	imageUrl: z.string().url().optional(),
});

export function getFalModelInfo(modelId: string) {
	return FAL_MODEL_MAP[modelId] ?? null;
}

export function estimateFalCost(modelId: string): number {
	return FAL_MODEL_MAP[modelId]?.costUnits ?? 0;
}

type FalBudgetDecision = { allowed: true } | { allowed: false; code: string; message: string };

const FAL_TIER_LIMITS: Record<PlanTier, { imagesPerDay: number; videosPerDay: number; videosPerMonth: number }> = {
	free:    { imagesPerDay: 0,  videosPerDay: 0, videosPerMonth: 0 },
	starter: { imagesPerDay: 3,  videosPerDay: 0, videosPerMonth: 0 },
	pro:     { imagesPerDay: 10, videosPerDay: 5, videosPerMonth: 5 },
	power:   { imagesPerDay: 30, videosPerDay: 15, videosPerMonth: 15 },
};

export async function checkFalBudget(
	env: Env,
	userId: string,
	planTier: PlanTier,
	generationType: GenerationType,
	modelId: string,
): Promise<FalBudgetDecision> {
	const modelInfo = FAL_MODEL_MAP[modelId];
	if (!modelInfo) return { allowed: false, code: "FAL_UNKNOWN_MODEL", message: "Unknown generation model." };

	// Check tier access
	if (TIER_ORDER[planTier] < TIER_ORDER[modelInfo.minTier]) {
		return { allowed: false, code: "FAL_TIER_LOCKED", message: `This model requires ${modelInfo.minTier} plan or higher.` };
	}

	const limits = FAL_TIER_LIMITS[planTier];
	const todayStart = new Date();
	todayStart.setUTCHours(0, 0, 0, 0);
	const todayIso = todayStart.toISOString();

	if (generationType === "image") {
		const row = await queryFirst<{ cnt: number }>(
			env.DB,
			"SELECT COUNT(*) as cnt FROM generations WHERE user_id = ? AND generation_type = 'image' AND created_at >= ? AND status != 'cancelled'",
			userId, todayIso,
		);
		if ((row?.cnt ?? 0) >= limits.imagesPerDay) {
			return { allowed: false, code: "FAL_DAILY_IMAGE_LIMIT", message: `Daily image limit reached (${limits.imagesPerDay}/day). Upgrade your plan for more.` };
		}
	} else {
		// video or image_to_video
		const dayRow = await queryFirst<{ cnt: number }>(
			env.DB,
			"SELECT COUNT(*) as cnt FROM generations WHERE user_id = ? AND generation_type IN ('video','image_to_video') AND created_at >= ? AND status != 'cancelled'",
			userId, todayIso,
		);
		if ((dayRow?.cnt ?? 0) >= limits.videosPerDay) {
			return { allowed: false, code: "FAL_DAILY_VIDEO_LIMIT", message: `Daily video limit reached (${limits.videosPerDay}/day). Upgrade your plan for more.` };
		}
		// Monthly video check
		const monthStart = new Date();
		monthStart.setUTCDate(1);
		monthStart.setUTCHours(0, 0, 0, 0);
		const monthIso = monthStart.toISOString();
		const monthRow = await queryFirst<{ cnt: number }>(
			env.DB,
			"SELECT COUNT(*) as cnt FROM generations WHERE user_id = ? AND generation_type IN ('video','image_to_video') AND created_at >= ? AND status != 'cancelled'",
			userId, monthIso,
		);
		if ((monthRow?.cnt ?? 0) >= limits.videosPerMonth) {
			return { allowed: false, code: "FAL_MONTHLY_VIDEO_LIMIT", message: `Monthly video limit reached (${limits.videosPerMonth}/month). Upgrade your plan for more.` };
		}
	}

	return { allowed: true };
}

export async function globalFalSpendCheck(env: Env): Promise<{ allowed: true } | { allowed: false; message: string }> {
	const maxDailyUnits = envInt(env, "TAI_FAL_GLOBAL_DAILY_LIMIT_UNITS", 1500000, 10000, 100000000); // ~$150
	const todayStart = new Date();
	todayStart.setUTCHours(0, 0, 0, 0);
	const todayIso = todayStart.toISOString();
	const row = await queryFirst<{ total: number }>(
		env.DB,
		"SELECT COALESCE(SUM(estimated_cost_units), 0) as total FROM generations WHERE created_at >= ? AND status != 'cancelled'",
		todayIso,
	);
	if ((row?.total ?? 0) >= maxDailyUnits) {
		return { allowed: false, message: "Image/video generation is temporarily unavailable due to capacity limits. Please try again later." };
	}
	return { allowed: true };
}

export async function submitFalGeneration(
	env: Env,
	userId: string,
	chatId: string | null,
	modelId: string,
	prompt: string,
	negativePrompt: string | null,
	params: Record<string, unknown>,
): Promise<{ id: string; falRequestId: string } | { error: string }> {
	const apiKey = envString(env, "FAL_AI_API_KEY");
	if (!apiKey) return { error: "Image generation is not configured." };

	const body: Record<string, unknown> = { prompt, ...params };
	if (negativePrompt) body.negative_prompt = negativePrompt;

	const res = await fetch(`https://queue.fal.run/${modelId}`, {
		method: "POST",
		headers: {
			Authorization: `Key ${apiKey}`,
			"Content-Type": "application/json",
		},
		body: JSON.stringify(body),
	});

	if (!res.ok) {
		const text = await res.text();
		return { error: `fal.ai error (${res.status}): ${text.slice(0, 200)}` };
	}

	const result = await res.json<{ request_id: string }>();
	const modelInfo = FAL_MODEL_MAP[modelId];
	const id = randomId();

	await exec(
		env.DB,
		`INSERT INTO generations (id, user_id, chat_id, fal_request_id, provider, model_id, model_display_name, generation_type, status, prompt, negative_prompt, parameters, estimated_cost_units, created_at)
		 VALUES (?, ?, ?, ?, 'fal', ?, ?, ?, 'queued', ?, ?, ?, ?, ?)`,
		id,
		userId,
		chatId ?? null,
		result.request_id,
		modelId,
		modelInfo?.displayName ?? modelId,
		modelInfo?.generationType ?? "image",
		prompt,
		negativePrompt ?? null,
		Object.keys(params).length > 0 ? JSON.stringify(params) : null,
		modelInfo?.costUnits ?? 0,
		nowIso(),
	);

	return { id, falRequestId: result.request_id };
}

export async function checkFalStatus(
	env: Env,
	falRequestId: string,
	modelId: string,
): Promise<{ status: string; queuePosition?: number; responseUrl?: string }> {
	const apiKey = envString(env, "FAL_AI_API_KEY");
	const res = await fetch(`https://queue.fal.run/${modelId}/requests/${falRequestId}/status`, {
		headers: { Authorization: `Key ${apiKey}` },
	});
	if (!res.ok) return { status: "unknown" };
	return res.json();
}

export async function getFalResult(
	env: Env,
	falRequestId: string,
	modelId: string,
): Promise<{ data: Record<string, unknown> } | { error: string }> {
	const apiKey = envString(env, "FAL_AI_API_KEY");
	const res = await fetch(`https://queue.fal.run/${modelId}/requests/${falRequestId}`, {
		headers: { Authorization: `Key ${apiKey}` },
	});
	if (!res.ok) {
		const text = await res.text();
		return { error: `fal.ai result error (${res.status}): ${text.slice(0, 200)}` };
	}
	return { data: await res.json() };
}

export async function getGenerationById(env: Env, userId: string, generationId: string): Promise<GenerationRecord | null> {
	const row = await queryFirst<any>(
		env.DB,
		"SELECT * FROM generations WHERE id = ? AND user_id = ?",
		generationId, userId,
	);
	if (!row) return null;
	return mapGeneration(row);
}

export async function listGenerations(env: Env, userId: string, limit = 50, offset = 0): Promise<GenerationRecord[]> {
	const rows = await queryAll<any>(
		env.DB,
		"SELECT * FROM generations WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?",
		userId, limit, offset,
	);
	return rows.map(mapGeneration);
}

export async function cancelGeneration(env: Env, userId: string, generationId: string): Promise<boolean> {
	const row = await queryFirst<{ id: string; status: string }>(
		env.DB,
		"SELECT id, status FROM generations WHERE id = ? AND user_id = ?",
		generationId, userId,
	);
	if (!row) return false;
	if (row.status !== "queued" && row.status !== "processing") return false;
	await exec(env.DB, "UPDATE generations SET status = 'cancelled', completed_at = ? WHERE id = ?", nowIso(), generationId);
	return true;
}

export async function updateGenerationStatus(
	env: Env,
	generationId: string,
	status: GenerationStatus,
	resultUrl?: string | null,
	resultMetadata?: Record<string, unknown> | null,
	errorMessage?: string | null,
): Promise<void> {
	const completedAt = status === "completed" || status === "failed" ? nowIso() : null;
	await exec(
		env.DB,
		`UPDATE generations SET status = ?, result_url = COALESCE(?, result_url), result_metadata = COALESCE(?, result_metadata), error_message = COALESCE(?, error_message), completed_at = COALESCE(?, completed_at) WHERE id = ?`,
		status,
		resultUrl ?? null,
		resultMetadata ? JSON.stringify(resultMetadata) : null,
		errorMessage ?? null,
		completedAt,
		generationId,
	);
}

function mapGeneration(row: any): GenerationRecord {
	return {
		id: row.id,
		userId: row.user_id,
		chatId: row.chat_id ?? null,
		falRequestId: row.fal_request_id,
		provider: row.provider,
		modelId: row.model_id,
		modelDisplayName: row.model_display_name ?? null,
		generationType: row.generation_type,
		status: row.status,
		prompt: row.prompt,
		negativePrompt: row.negative_prompt ?? null,
		parameters: row.parameters ?? null,
		resultUrl: row.result_url ?? null,
		resultMetadata: row.result_metadata ?? null,
		estimatedCostUnits: row.estimated_cost_units ?? 0,
		actualCostUnits: row.actual_cost_units ?? null,
		errorMessage: row.error_message ?? null,
		createdAt: row.created_at,
		completedAt: row.completed_at ?? null,
	};
}

// ══════════════════════════════════════════════════════════════════
// TABAI COMPOSITE MODEL — SMART ROUTING
// ══════════════════════════════════════════════════════════════════

const TABAI_MODEL_ID = "tabai";

const TABAI_ROUTES = {
	code: "qwen/qwen-2.5-coder-7b-instruct",
	math: "microsoft/phi-3-mini-128k-instruct",
	creative: "meta-llama/llama-3.1-8b-instruct",
	turkish: "qwen/qwen-2.5-7b-instruct",
	quick: "meta-llama/llama-3.2-3b-instruct",
	default: "google/gemma-2-9b-it",
} as const;

const CODE_KEYWORDS = /\b(function|class|import|export|const|let|var|error|bug|code|debug|api|sql|html|css|react|python|javascript|typescript|async|await|promise|array|object|loop|regex|compile|runtime|npm|git)\b/i;
const MATH_KEYWORDS = /\b(calculate|equation|proof|math|solve|integral|derivative|matrix|algebra|theorem|formula|geometry|statistics|probability|factorial)\b/i;
const CREATIVE_KEYWORDS = /\b(write|story|poem|creative|imagine|fiction|novel|essay|lyrics|script|dialogue|narrative|compose|rewrite|draft)\b/i;
const TURKISH_CHARS = /[çğıöşüÇĞİÖŞÜ]/;

export function isTabaiModel(modelId: string): boolean {
	return modelId === TABAI_MODEL_ID || modelId === "tabai-free";
}

export function routeTabaiModel(messages: Array<{ role: string; content: string }>): { actualModelId: string; routeReason: string } {
	const lastUserMsg = [...messages].reverse().find((m) => m.role === "user");
	if (!lastUserMsg) return { actualModelId: TABAI_ROUTES.default, routeReason: "default" };

	const text = lastUserMsg.content;

	if (TURKISH_CHARS.test(text)) return { actualModelId: TABAI_ROUTES.turkish, routeReason: "turkish" };
	if (CODE_KEYWORDS.test(text)) return { actualModelId: TABAI_ROUTES.code, routeReason: "code" };
	if (MATH_KEYWORDS.test(text)) return { actualModelId: TABAI_ROUTES.math, routeReason: "math" };
	if (CREATIVE_KEYWORDS.test(text)) return { actualModelId: TABAI_ROUTES.creative, routeReason: "creative" };
	if (text.length < 20) return { actualModelId: TABAI_ROUTES.quick, routeReason: "quick" };

	return { actualModelId: TABAI_ROUTES.default, routeReason: "default" };
}

export function tabaiVirtualModel(): ModelRecord {
	return {
		id: TABAI_MODEL_ID,
		providerId: "tabai",
		slug: "tabai",
		providerModelId: "tabai",
		displayName: "TABAI",
		logoUrl: null,
		description: "Smart AI — automatically picks the best model for your question",
		enabled: true,
		supportsStreaming: true,
		supportsTextChat: true,
		supportsVision: false,
		supportsReasoning: false,
		supportsImageGeneration: false,
		vendor: "tabai",
		capabilities: ["streaming"],
		verified: true,
		verificationStatus: "verified",
		contextLength: 32768,
		pricingTier: "free",
		category: "free-basic",
		requiredPlanTier: "free",
		canAccess: true,
		lockReason: null,
		provider: {
			id: "tabai",
			name: "TABAI",
			slug: "tabai",
			type: "composite",
			endpointUrl: "",
			enabled: true,
		},
	};
}
