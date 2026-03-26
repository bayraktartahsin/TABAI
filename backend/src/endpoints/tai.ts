import { Bool, OpenAPIRoute, Str } from "chanfana";
import { z } from "zod";
import type { AppContext } from "../types";
import {
	adminModelPatchSchema,
	adminEntitlementPatchSchema,
	adminModelPostSchema,
	adminUserCreateSchema,
	adminUserPatchSchema,
	applyRateLimitHeaders,
	applyRequestTokenGuard,
	applyCors,
	acquireStreamLease,
	authenticateUser,
	checkGlobalSpendCircuit,
	checkRollingUsageBudget,
	checkStreamQuota,
	consumeSlidingWindowRateLimit,
	chatCreateSchema,
	chatPatchSchema,
	clearSessionHeader,
	consumeRateLimit,
	createAdminModel,
	createChat,
	createFolder,
	createMessage,
	createSessionCookie,
	deleteChat,
	deleteFolder,
	folderCreateSchema,
	folderPatchSchema,
	getClientIp,
	getAccessibleModelById,
	getChat,
	getSettings,
	getUserById,
	jsonError,
	listAdminChats,
	listAdminModels,
	listAdminProviders,
	listAudit,
	listFolders,
	listMessages,
	listUsers,
	logAudit,
	messageCreateSchema,
	patchAdminModel,
	patchUser,
	permissionsPutSchema,
	passwordResetConfirmSchema,
	passwordResetRequestSchema,
	preflight,
	recordUsageEvent,
	recordStreamLedgerFinalize,
	recordStreamLedgerStart,
	releaseStreamLease,
	requireUser,
	requestEmailVerification,
	requestPasswordReset,
	saveUserPermissions,
	sanitizeUser,
	serializeBootstrap,
	serializeChats,
	settingsAccountSchema,
	settingsPatchSchema,
	setSessionHeader,
	signupSchema,
	signinSchema,
	sseEvent,
	estimateCostUnits,
	estimateTokensForMessages,
	enforceExpensiveModelAccess,
	hardCompletionTokenLimit,
	applyHardPromptGuard,
	recordSafetyEvent,
	recordStreamLedgerRejection,
	reserveDailyCostLedgerStart,
	streamOpenRouter,
	streamSchema,
	streamOutputCharLimit,
	syncModelsIfNeeded,
	confirmEmailVerification,
	confirmPasswordReset,
	verifyTokenSchema,
	verificationRequestSchema,
	setCsrfCookie,
	validateCsrf,
	signupUser,
	updateAccount,
	updateChat,
	updateFolder,
	updateSettings,
	createUser,
	getUserPermissions,
	removeUser,
	getUserEntitlement,
	setAdminUserEntitlement,
	storeEntitlementSyncSchema,
	syncStoreEntitlement,
	getUserUsageSnapshot,
	findOrCreateAppleUser,
	getAdminOverviewStats,
	getAdminUserGrowth,
	getAdminModelUsage,
	getAdminRevenueBreakdown,
	getAdminSafetyEvents,
	getAdminErrorSummary,
	getAdminUserChats,
	listAdminNotes,
	createAdminNote,
	listDiscountCodes,
	createDiscountCode,
	deleteDiscountCode,
	redeemDiscountCode,
	listUsersPaginated,
	getSystemHealth,
	falGenerateImageSchema,
	falGenerateVideoSchema,
	getFalModelInfo,
	estimateFalCost,
	checkFalBudget,
	getFalQuotaSnapshot,
	globalFalSpendCheck,
	submitFalGeneration,
	checkFalStatus,
	getFalResult,
	getGenerationById,
	listGenerations,
	cancelGeneration,
	updateGenerationStatus,
	isTabaiModel,
	routeTabaiModel,
	tabaiVirtualModel,
	checkChatCategoryQuota,
	incrementChatCategoryCount,
	CHAT_TIER_LIMITS,
	type ModelCategory,
} from "../lib";
import {
	BootstrapSchema,
	ChatSchema,
	EntitlementSchema,
	FolderSchema,
	MessageSchema,
	ModelSchema,
	SettingsSchema,
	UserSchema,
} from "../types";
import { memoryCache } from "../cache-compat";

const SigninBody = z.object(signinSchema.shape);
const SignupBody = z.object(signupSchema.shape);
const ChatCreateBody = z.object(chatCreateSchema.shape);
const ChatPatchBody = z.object(chatPatchSchema.shape);
const MessageCreateBody = z.object(messageCreateSchema.shape);
const FolderCreateBody = z.object(folderCreateSchema.shape);
const FolderPatchBody = z.object(folderPatchSchema.shape);
const SettingsPatchBody = z.object(settingsPatchSchema.shape);
const SettingsAccountBody = z.object(settingsAccountSchema.shape);
const StreamBody = z.object(streamSchema.shape);
const AdminUserCreateBody = z.object(adminUserCreateSchema.shape);
const AdminUserPatchBody = z.object(adminUserPatchSchema.shape);
const PermissionsBody = z.object(permissionsPutSchema.shape);
const AdminModelPostBody = z.object(adminModelPostSchema.shape);
const AdminModelPatchBody = z.object(adminModelPatchSchema.shape);
const AdminEntitlementPatchBody = z.object(adminEntitlementPatchSchema.shape);
const VerifyTokenBody = z.object(verifyTokenSchema.shape);
const VerificationRequestBody = z.object(verificationRequestSchema.shape);
const PasswordResetRequestBody = z.object(passwordResetRequestSchema.shape);
const PasswordResetConfirmBody = z.object(passwordResetConfirmSchema.shape);
const StoreEntitlementSyncBody = storeEntitlementSyncSchema;

const IdParam = z.object({ id: Str() });
const ChatIdParam = z.object({ chatId: Str() });
const FolderIdParam = z.object({ folderId: Str() });
const UserIdParam = z.object({ userId: Str() });
const ModelIdParam = z.object({ modelId: Str() });
const ProviderIdParam = z.object({ providerId: Str() });

function authRequired(c: AppContext) {
	return jsonError(c, 401, "Unauthorized", "AUTH_REQUIRED");
}

function csrfRequired(c: AppContext) {
	return jsonError(c, 403, "CSRF token mismatch.", "CSRF_MISMATCH");
}

function rateLimited(c: AppContext, message: string, decision: { retryAfterSec: number; limit: number; remaining: number; windowSec: number }) {
	applyCors(c);
	applyRateLimitHeaders(c, decision);
	return c.json({ error: message, code: "RATE_LIMITED" }, 429);
}

type StreamAttachment = {
	type: "image_url" | "text_file";
	name?: string;
	mime?: string;
	size?: number;
	image_url?: { url?: string };
	text?: string;
};

type OpenRouterMessage = {
	role: "system" | "user" | "assistant";
	content:
	| string
	| Array<{ type: "text"; text: string } | { type: "image_url"; image_url: { url: string } }>;
};

function applyAttachmentsToMessages(
	messages: Array<{ role: "system" | "user" | "assistant"; content: string }>,
	attachments: StreamAttachment[] | undefined,
): OpenRouterMessage[] {
	if (!attachments?.length) return messages;
	const imageAttachments = attachments.filter((item) => item.type === "image_url" && item.image_url?.url);
	const textFileAttachments = attachments.filter((item) => item.type === "text_file" && typeof item.text === "string");
	if (!imageAttachments.length && !textFileAttachments.length) return messages;

	const lastUserIndex = [...messages].map((item) => item.role).lastIndexOf("user");
	if (lastUserIndex < 0) return messages;
	const base = messages[lastUserIndex];
	const next = messages.slice();

	if (imageAttachments.length > 0) {
		const multimodal: Array<{ type: "text"; text: string } | { type: "image_url"; image_url: { url: string } }> = [];
		multimodal.push({ type: "text", text: base.content });
		for (const file of textFileAttachments) {
			multimodal.push({
				type: "text",
				text: `Attached file: ${file.name ?? "document"}\n\n${file.text ?? ""}`,
			});
		}
		for (const image of imageAttachments) {
			multimodal.push({ type: "image_url", image_url: { url: String(image.image_url!.url) } });
		}
		return next.map((message, index) => (
			index === lastUserIndex
				? { role: message.role, content: multimodal }
				: { role: message.role, content: message.content }
		));
	}

	const appendedText = textFileAttachments
		.map((file) => `\n\nAttached file: ${file.name ?? "document"}\n\n${file.text ?? ""}`)
		.join("");
	next[lastUserIndex] = { ...base, content: `${base.content}${appendedText}` };
	return next.map((message) => ({ role: message.role, content: message.content }));
}

function userCacheRequest(c: AppContext, scope: string, userId: string) {
	const url = new URL(c.req.url);
	url.pathname = `/_edge-cache/${scope}`;
	url.search = `user=${encodeURIComponent(userId)}`;
	return new Request(url.toString(), { method: "GET" });
}

async function getCachedJson(c: AppContext, key: Request) {
	const cached = await memoryCache.match(key);
	if (!cached) return null;
	applyCors(c);
	for (const [header, value] of cached.headers.entries()) {
		if (header.toLowerCase() === "content-length") continue;
		c.header(header, value);
	}
	return c.newResponse(cached.body, cached.status);
}

function storeCachedJson(key: Request, response: Response) {
	return memoryCache.put(key, response.clone());
}

function invalidateUserCaches(c: AppContext, userId: string) {
	return Promise.allSettled([
		memoryCache.delete(userCacheRequest(c, "bootstrap", userId)),
		memoryCache.delete(userCacheRequest(c, "models", userId)),
	]);
}

async function requireAdmin(c: AppContext) {
	const user = await requireUser(c);
	if (!user) return { error: authRequired(c) };
	if (user.role !== "ADMIN") return { error: jsonError(c, 403, "Forbidden.") };
	return { user };
}

export class OptionsRoute extends OpenAPIRoute {
	schema = { tags: ["System"], summary: "CORS preflight", responses: { "204": { description: "No content" } } };
	async handle(c: AppContext) {
		return preflight(c);
	}
}

export class HealthRoute extends OpenAPIRoute {
	schema = {
		tags: ["System"],
		summary: "Health check",
		responses: {
			"200": {
				description: "Healthy worker",
				content: { "application/json": { schema: z.object({ ok: Bool(), provider: z.string() }) } },
			},
		},
	};

	async handle(c: AppContext) {
		applyCors(c);
		return c.json({ ok: true, provider: "openrouter" });
	}
}

export class AuthSignInRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Sign in",
		request: { body: { content: { "application/json": { schema: SigninBody } } } },
		responses: { "200": { description: "Authenticated user", content: { "application/json": { schema: z.object({ user: UserSchema }) } } } },
	};

	async handle(c: AppContext) {
		const ip = getClientIp(c) ?? "unknown";
		const limit = await consumeRateLimit(c.env, {
			scope: "auth_signin_ip",
			identifier: ip,
			limit: 8,
			windowSec: 300,
		});
		if (limit.limited) {
			return rateLimited(c, "Too many sign-in attempts. Please wait before trying again.", limit);
		}
		const data = await this.getValidatedData<typeof this.schema>();
		const auth = await authenticateUser(c.env, data.body.email, data.body.password);
		if (!auth.ok) {
			if (auth.code === "EMAIL_NOT_VERIFIED") {
				applyCors(c);
				return c.json({
					error: "Please verify your email address. Check your inbox for the verification link.",
					code: "EMAIL_NOT_VERIFIED",
				}, 403);
			}
			return jsonError(c, 401, "Invalid credentials.");
		}
		const token = await createSessionCookie(c.env, auth.user);
		applyCors(c);
		setSessionHeader(c, token);
		setCsrfCookie(c);
		return c.json({ user: sanitizeUser(auth.user) });
	}
}

export class AuthAppleRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Sign in with Apple",
		request: {
			body: {
				content: {
					"application/json": {
						schema: z.object({
							identityToken: z.string(),
							email: z.string().optional(),
							displayName: z.string().optional(),
						}),
					},
				},
			},
		},
		responses: {
			"200": {
				description: "Authenticated user",
				content: { "application/json": { schema: z.object({ user: UserSchema }) } },
			},
		},
	};

	async handle(c: AppContext) {
		const ip = getClientIp(c) ?? "unknown";
		const limit = await consumeRateLimit(c.env, {
			scope: "auth_apple_ip",
			identifier: ip,
			limit: 10,
			windowSec: 300,
		});
		if (limit.limited) {
			return rateLimited(c, "Too many attempts. Please wait.", limit);
		}

		const data = await this.getValidatedData<typeof this.schema>();
		const { identityToken, email, displayName } = data.body;

		// Decode the Apple JWT payload (header.payload.signature)
		const parts = identityToken.split(".");
		if (parts.length !== 3) {
			return jsonError(c, 400, "Invalid Apple identity token format.");
		}

		let payload: { sub?: string; email?: string; email_verified?: boolean | string; iss?: string; aud?: string; exp?: number };
		try {
			// Base64url → base64: replace URL-safe chars and add padding
			let b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
			while (b64.length % 4 !== 0) b64 += "=";
			const decoded = atob(b64);
			payload = JSON.parse(decoded);
		} catch {
			return jsonError(c, 400, "Could not decode Apple identity token.");
		}

		// Validate issuer
		if (payload.iss !== "https://appleid.apple.com") {
			return jsonError(c, 401, "Invalid Apple token issuer.");
		}

		const appleUserId = payload.sub;
		if (!appleUserId) {
			return jsonError(c, 401, "Apple token missing subject.");
		}

		// Check expiration (Apple JWTs expire after ~5 min, allow 60s grace)
		if (payload.exp && payload.exp < Math.floor(Date.now() / 1000) - 60) {
			return jsonError(c, 401, "Apple identity token has expired. Please try signing in again.");
		}

		// Log audience for debugging (don't reject — iPad/iPhone may differ)
		if (payload.aud) {
			console.log(`Apple Sign-In aud: ${payload.aud}`);
		}

		// Use email from token or from request body (may be null on subsequent Apple sign-ins)
		const resolvedEmail = payload.email || email || null;

		// Find or create user — looks up by appleUserId first, email second
		const result = await findOrCreateAppleUser(c.env, resolvedEmail, appleUserId, displayName ?? null);
		if (!result.user) {
			return jsonError(c, 400, "Unable to complete sign in. Please try again or use a different sign-in method.", "APPLE_NO_EMAIL");
		}

		const token = await createSessionCookie(c.env, result.user);
		applyCors(c);
		setSessionHeader(c, token);
		setCsrfCookie(c);
		return c.json({ user: sanitizeUser(result.user) });
	}
}

export class AuthGoogleRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Start Google OAuth flow",
		request: { query: z.object({ platform: z.enum(["web", "ios", "android"]).optional() }) },
		responses: { "302": { description: "Redirect to Google" } },
	};
	async handle(c: AppContext) {
		const data = await this.getValidatedData<typeof this.schema>();
		const platform = data.query.platform || "web";
		const clientId = (c.env as any).GOOGLE_CLIENT_ID;
		if (!clientId) return jsonError(c, 501, "Google Sign-In not configured.");
		const redirectUri = `https://ai.gravitilabs.com/api/auth/google/callback`;
		const scope = encodeURIComponent("email profile openid");
		const state = platform !== "web" ? encodeURIComponent(platform) : "";
		const stateParam = state ? `&state=${state}` : "";
		const url = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&response_type=code&scope=${scope}&access_type=offline&prompt=select_account${stateParam}`;
		return c.redirect(url, 302);
	}
}

export class AuthGoogleCallbackRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Google OAuth callback",
		request: { query: z.object({ code: z.string().optional(), error: z.string().optional(), state: z.string().optional() }) },
		responses: { "302": { description: "Redirect to app" } },
	};
	async handle(c: AppContext) {
		const data = await this.getValidatedData<typeof this.schema>();
		const code = data.query.code;
		const platform = data.query.state || "web"; // state carries the platform
		if (!code) return jsonError(c, 400, "OAuth error: " + (data.query.error || "no code"));

		const clientId = (c.env as any).GOOGLE_CLIENT_ID;
		const clientSecret = (c.env as any).GOOGLE_CLIENT_SECRET;
		if (!clientId || !clientSecret) return jsonError(c, 501, "Google Sign-In not configured.");

		const redirectUri = `https://ai.gravitilabs.com/api/auth/google/callback`;

		// Exchange code for tokens
		const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
			method: "POST",
			headers: { "Content-Type": "application/x-www-form-urlencoded" },
			body: new URLSearchParams({
				code,
				client_id: clientId,
				client_secret: clientSecret,
				redirect_uri: redirectUri,
				grant_type: "authorization_code",
			}).toString(),
		});

		if (!tokenRes.ok) return jsonError(c, 401, "Failed to exchange Google code.");
		const tokens = (await tokenRes.json()) as { id_token?: string; access_token?: string };

		// Get user info
		const userInfoRes = await fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
			headers: { Authorization: `Bearer ${tokens.access_token}` },
		});
		if (!userInfoRes.ok) return jsonError(c, 401, "Failed to get Google user info.");
		const userInfo = (await userInfoRes.json()) as { email?: string; name?: string; id?: string };

		if (!userInfo.email) return jsonError(c, 400, "No email from Google.");

		// Find or create user
		const result = await findOrCreateAppleUser(c.env, userInfo.email, `google:${userInfo.id ?? ""}`, userInfo.name ?? null);
		if (!result.user) return jsonError(c, 500, "Could not create account.");

		// Set session cookie
		const token = await createSessionCookie(c.env, result.user);
		applyCors(c);
		setSessionHeader(c, token);
		setCsrfCookie(c);

		if (platform === "ios" || platform === "android") {
			// Redirect to native app via custom URL scheme with session token
			const callbackUrl = `tabai://auth/callback?token=${encodeURIComponent(token)}&email=${encodeURIComponent(userInfo.email)}&status=ok`;
			return c.redirect(callbackUrl, 302);
		}

		// Web: redirect to app root (session cookie is already set)
		return c.redirect("https://ai.gravitilabs.com/", 302);
	}
}

export class AuthSignupRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Public signup",
		request: { body: { content: { "application/json": { schema: SignupBody } } } },
		responses: { "201": { description: "Created account" } },
	};

	async handle(c: AppContext) {
		const ip = getClientIp(c) ?? "unknown";
		const limit = await consumeRateLimit(c.env, {
			scope: "auth_signup_ip",
			identifier: ip,
			limit: 6,
			windowSec: 600,
		});
		if (limit.limited) return rateLimited(c, "Too many signup attempts. Please try later.", limit);
		const data = await this.getValidatedData<typeof this.schema>();
		const result = await signupUser(c.env, data.body);
		if (!result.ok) {
			return jsonError(c, 400, (result as { error: string; code: string }).error, (result as { error: string; code: string }).code);
		}
		applyCors(c);
		return c.json({
			success: true,
			verificationRequired: true,
			message: "Check your email to verify your account.",
			verificationEmailSent: result.verificationEmailSent,
			verificationToken: result.verificationToken,
			verificationTokenExpiresAt: result.verificationTokenExpiresAt,
		}, 201);
	}
}

export class AuthVerificationRequestRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Request verification email/token",
		request: { body: { content: { "application/json": { schema: VerificationRequestBody } } } },
		responses: { "200": { description: "Requested" } },
	};

	async handle(c: AppContext) {
		const ip = getClientIp(c) ?? "unknown";
		const limit = await consumeRateLimit(c.env, {
			scope: "auth_verify_request_ip",
			identifier: ip,
			limit: 12,
			windowSec: 600,
		});
		if (limit.limited) return rateLimited(c, "Too many verification requests. Please wait.", limit);
		const data = await this.getValidatedData<typeof this.schema>();
		const result = await requestEmailVerification(c.env, data.body.email);
		applyCors(c);
		return c.json({
			ok: true,
			requested: true,
			verificationToken: result.verificationToken,
			verificationTokenExpiresAt: result.verificationTokenExpiresAt,
		});
	}
}

export class AuthVerificationConfirmRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Confirm email verification token",
		request: { body: { content: { "application/json": { schema: VerifyTokenBody } } } },
		responses: { "200": { description: "Verified" } },
	};

	async handle(c: AppContext) {
		const data = await this.getValidatedData<typeof this.schema>();
		const result = await confirmEmailVerification(c.env, data.body.token);
		if (!result.ok) {
			const code = result.code === "TOKEN_EXPIRED" ? 410 : 400;
			return jsonError(c, code, "Verification token is invalid or expired.", result.code);
		}
		applyCors(c);
		return c.json({ ok: true, user: result.user });
	}
}

export class AuthPasswordResetRequestRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Request password reset",
		request: { body: { content: { "application/json": { schema: PasswordResetRequestBody } } } },
		responses: { "200": { description: "Requested" } },
	};

	async handle(c: AppContext) {
		const ip = getClientIp(c) ?? "unknown";
		const limit = await consumeRateLimit(c.env, {
			scope: "auth_reset_request_ip",
			identifier: ip,
			limit: 10,
			windowSec: 600,
		});
		if (limit.limited) return rateLimited(c, "Too many password reset requests. Please wait.", limit);
		const data = await this.getValidatedData<typeof this.schema>();
		const result = await requestPasswordReset(c.env, data.body.email);
		applyCors(c);
		return c.json({
			ok: true,
			requested: true,
			resetToken: result.resetToken,
			resetTokenExpiresAt: result.resetTokenExpiresAt,
		});
	}
}

export class AuthPasswordResetConfirmRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Confirm password reset",
		request: { body: { content: { "application/json": { schema: PasswordResetConfirmBody } } } },
		responses: { "200": { description: "Password updated" } },
	};

	async handle(c: AppContext) {
		const data = await this.getValidatedData<typeof this.schema>();
		const result = await confirmPasswordReset(c.env, data.body.token, data.body.newPassword);
		if (!result.ok) {
			const code = result.code === "TOKEN_EXPIRED" ? 410 : 400;
			return jsonError(c, code, "Reset token is invalid or expired.", result.code);
		}
		applyCors(c);
		return c.json({ ok: true, user: result.user });
	}
}

export class AuthMeRoute extends OpenAPIRoute {
	schema = {
		tags: ["Auth"],
		summary: "Current user",
		responses: { "200": { description: "Authenticated user", content: { "application/json": { schema: z.object({ user: UserSchema.nullable() }) } } } },
	};

	async handle(c: AppContext) {
		applyCors(c);
		const user = await requireUser(c);
		if (!user) return c.json({ user: null, error: "Unauthorized", code: "AUTH_REQUIRED" }, 401);
		return c.json({ user: sanitizeUser(user) });
	}
}

export class AuthSignOutRoute extends OpenAPIRoute {
	schema = { tags: ["Auth"], summary: "Sign out", responses: { "200": { description: "Signed out" } } };
	async handle(c: AppContext) {
		applyCors(c);
		clearSessionHeader(c);
		return c.json({ ok: true });
	}
}

export class StoreEntitlementSyncRoute extends OpenAPIRoute {
	schema = {
		tags: ["Entitlements"],
		summary: "Store entitlement sync intake (Apple/Google)",
		request: { body: { content: { "application/json": { schema: StoreEntitlementSyncBody } } } },
		responses: {
			"202": {
				description: "Accepted for validation",
				content: {
					"application/json": {
						schema: z.object({
							accepted: z.boolean(),
							provider: z.enum(["apple", "google"]),
							verificationState: z.enum(["verified", "pending_validation", "invalid", "error"]),
							code: z.string(),
							message: z.string(),
							entitlement: EntitlementSchema.nullable(),
							latestEntitlement: EntitlementSchema.nullable(),
							debugSummary: z.string().nullable().optional(),
						}),
					},
				},
			},
		},
	};

	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		try {
			const data = await this.getValidatedData<typeof this.schema>();
			const result = await syncStoreEntitlement(c.env, user, data.body);
			// Store sync can change effective plan and model access immediately.
			// Clear user-scoped cached payloads so bootstrap/models reflect the new entitlement.
			void (invalidateUserCaches(c, user.id));
			applyCors(c);
			return c.json(result, 202);
		} catch (error) {
			console.error("[store-sync] unhandled route error", error);
			applyCors(c);
			const isValidationError = !!error && typeof error === "object" && (
				"issues" in error ||
				"errors" in error ||
				(error instanceof Error && /validation|schema|parse/i.test(error.name + " " + error.message))
			);
			return c.json({
				code: isValidationError ? "INVALID_STORE_PAYLOAD" : "STORE_SYNC_INTERNAL",
				message: error instanceof Error
					? error.message
					: (isValidationError ? "Store sync payload could not be processed." : "Store sync crashed before a structured result was produced."),
				verificationState: "error",
				debugSummary: error instanceof Error ? error.message : String(error),
			}, isValidationError ? 400 : 500);
		}
	}
}

export class BootstrapRoute extends OpenAPIRoute {
	schema = {
		tags: ["Bootstrap"],
		summary: "Bootstrap app state",
		responses: { "200": { description: "Initial app payload", content: { "application/json": { schema: BootstrapSchema } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);
		setCsrfCookie(c);
		c.header("Cache-Control", "no-store");
		return c.json(await serializeBootstrap(user, c.env));
	}
}

export class ModelsRoute extends OpenAPIRoute {
	schema = {
		tags: ["Models"],
		summary: "List models",
		responses: { "200": { description: "Models", content: { "application/json": { schema: z.object({ models: z.array(ModelSchema) }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);
		c.header("Cache-Control", "no-store");
		const bootstrap = await serializeBootstrap(user, c.env);
		return c.json({ models: bootstrap.models });
	}
}

export class ChatsRoute extends OpenAPIRoute {
	schema = {
		tags: ["Chats"],
		summary: "List chats",
		responses: { "200": { description: "Chats", content: { "application/json": { schema: z.object({ chats: z.array(ChatSchema) }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);
		return c.json({ chats: await serializeChats(user, c.env) });
	}
}

export class ChatsCreateRoute extends OpenAPIRoute {
	schema = {
		tags: ["Chats"],
		summary: "Create chat",
		request: { body: { content: { "application/json": { schema: ChatCreateBody } } } },
		responses: { "201": { description: "Created chat", content: { "application/json": { schema: z.object({ chat: ChatSchema }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const created = await createChat(user, c.env, data.body);
		const chats = await serializeChats(user, c.env, true);
		const chat = chats.find((item) => item.id === created.id);
		applyCors(c);
		void (invalidateUserCaches(c, user.id));
		return c.json({ chat }, 201);
	}
}

export class ChatsPatchRoute extends OpenAPIRoute {
	schema = {
		tags: ["Chats"],
		summary: "Update chat",
		request: {
			params: IdParam,
			body: { content: { "application/json": { schema: ChatPatchBody } } },
		},
		responses: { "200": { description: "Updated chat", content: { "application/json": { schema: z.object({ chat: ChatSchema }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const updated = await updateChat(user, c.env, data.params.id, data.body);
		if (!updated) return jsonError(c, 404, "Chat not found.");
		const chats = await serializeChats(user, c.env, true);
		applyCors(c);
		void (invalidateUserCaches(c, user.id));
		return c.json({ chat: chats.find((item) => item.id === data.params.id) ?? null });
	}
}

export class ChatsDeleteRoute extends OpenAPIRoute {
	schema = {
		tags: ["Chats"],
		summary: "Delete chat",
		request: { params: IdParam },
		responses: { "200": { description: "Deleted" } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const purge = c.req.query("purge") === "1";
		const ok = await deleteChat(user, c.env, data.params.id, purge);
		if (!ok) return jsonError(c, 404, "Chat not found.");
		applyCors(c);
		void (invalidateUserCaches(c, user.id));
		return c.json({ ok: true, deleted: data.params.id });
	}
}

export class ChatMessagesRoute extends OpenAPIRoute {
	schema = {
		tags: ["Chats"],
		summary: "List chat messages",
		request: { params: ChatIdParam },
		responses: { "200": { description: "Messages", content: { "application/json": { schema: z.object({ messages: z.array(MessageSchema) }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const messages = await listMessages(user, c.env, data.params.chatId);
		if (!messages) return jsonError(c, 404, "Chat not found.");
		applyCors(c);
		return c.json({ messages });
	}
}

export class ChatMessagesCreateRoute extends OpenAPIRoute {
	schema = {
		tags: ["Chats"],
		summary: "Create chat message",
		request: {
			params: ChatIdParam,
			body: { content: { "application/json": { schema: MessageCreateBody } } },
		},
		responses: { "201": { description: "Created", content: { "application/json": { schema: z.object({ message: MessageSchema }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const message = await createMessage(user, c.env, data.params.chatId, data.body);
		if (!message) return jsonError(c, 404, "Chat not found.");
		applyCors(c);
		void (invalidateUserCaches(c, user.id));
		return c.json({ message }, 201);
	}
}

export class FoldersListRoute extends OpenAPIRoute {
	schema = { tags: ["Folders"], summary: "List folders", responses: { "200": { description: "Folders", content: { "application/json": { schema: z.object({ folders: z.array(FolderSchema) }) } } } } };
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);
		return c.json({ folders: await listFolders(user, c.env) });
	}
}

export class FoldersCreateRoute extends OpenAPIRoute {
	schema = {
		tags: ["Folders"],
		summary: "Create folder",
		request: { body: { content: { "application/json": { schema: FolderCreateBody } } } },
		responses: { "201": { description: "Created", content: { "application/json": { schema: z.object({ folder: FolderSchema }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		const folder = await createFolder(user, c.env, data.body);
		void (invalidateUserCaches(c, user.id));
		return c.json({ folder }, 201);
	}
}

export class FoldersPatchRoute extends OpenAPIRoute {
	schema = {
		tags: ["Folders"],
		summary: "Update folder",
		request: {
			params: FolderIdParam,
			body: { content: { "application/json": { schema: FolderPatchBody } } },
		},
		responses: { "200": { description: "Updated", content: { "application/json": { schema: z.object({ folder: FolderSchema }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const folder = await updateFolder(user, c.env, data.params.folderId, data.body);
		if (!folder) return jsonError(c, 404, "Folder not found.");
		applyCors(c);
		void (invalidateUserCaches(c, user.id));
		return c.json({ folder });
	}
}

export class FoldersDeleteRoute extends OpenAPIRoute {
	schema = { tags: ["Folders"], summary: "Delete folder", request: { params: FolderIdParam }, responses: { "200": { description: "Deleted" } } };
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const ok = await deleteFolder(user, c.env, data.params.folderId);
		if (!ok) return jsonError(c, 404, "Folder not found.");
		applyCors(c);
		void (invalidateUserCaches(c, user.id));
		return c.json({ ok: true });
	}
}

export class SettingsGetRoute extends OpenAPIRoute {
	schema = { tags: ["Settings"], summary: "Get settings", responses: { "200": { description: "Settings", content: { "application/json": { schema: z.object({ settings: SettingsSchema }) } } } } };
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);
		return c.json({ settings: await getSettings(user, c.env) });
	}
}

export class SettingsPatchRoute extends OpenAPIRoute {
	schema = {
		tags: ["Settings"],
		summary: "Update settings",
		request: { body: { content: { "application/json": { schema: SettingsPatchBody } } } },
		responses: { "200": { description: "Updated", content: { "application/json": { schema: z.object({ settings: SettingsSchema }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		const settings = await updateSettings(user, c.env, data.body);
		void (invalidateUserCaches(c, user.id));
		return c.json({ settings });
	}
}

export class SettingsAccountPatchRoute extends OpenAPIRoute {
	schema = {
		tags: ["Settings"],
		summary: "Update account",
		request: { body: { content: { "application/json": { schema: SettingsAccountBody } } } },
		responses: { "200": { description: "Updated account", content: { "application/json": { schema: z.object({ user: UserSchema }) } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const updated = await updateAccount(user, c.env, data.body);
		if (updated.errorCode === "CURRENT_PASSWORD_REQUIRED") {
			return jsonError(c, 400, "Current password is required to set a new password.", "CURRENT_PASSWORD_REQUIRED");
		}
		if (updated.errorCode === "CURRENT_PASSWORD_INVALID") {
			return jsonError(c, 401, "Current password is incorrect.", "CURRENT_PASSWORD_INVALID");
		}
		if (!updated.user) return jsonError(c, 404, "User not found.");
		const token = await createSessionCookie(c.env, updated.user);
		applyCors(c);
		setSessionHeader(c, token);
		void (invalidateUserCaches(c, user.id));
		return c.json({ user: updated.user });
	}
}

export class UsageRoute extends OpenAPIRoute {
	schema = {
		tags: ["Usage"],
		summary: "Get current usage snapshot",
		responses: {
			"200": {
				description: "Usage snapshot",
				content: {
					"application/json": {
						schema: z.object({
							planTier: z.string(),
							tokensUsed: z.number(),
							tokenLimit: z.number(),
							costUnitsUsed: z.number(),
							costUnitLimit: z.number(),
							requestCount: z.number(),
							windowHours: z.number(),
							resetAt: z.string(),
						}),
					},
				},
			},
		},
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);
		c.header("Cache-Control", "no-store");
		const snapshot = await getUserUsageSnapshot(c.env, user.id, user.planTier);
		return c.json(snapshot);
	}
}

export class ChatStreamRoute extends OpenAPIRoute {
	schema = {
		tags: ["Chats"],
		summary: "Stream chat completion",
		request: { body: { content: { "application/json": { schema: StreamBody } } } },
		responses: { "200": { description: "SSE stream", content: { "text/event-stream": { schema: z.any() } } } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const ip = getClientIp(c) ?? "unknown";
		const logSafety = (input: Parameters<typeof recordSafetyEvent>[1]) =>
			recordSafetyEvent(c.env, {
				...input,
				userId: input.userId ?? user.id,
				ip: input.ip ?? ip,
			});

		const hardRpmLimit = await consumeSlidingWindowRateLimit(c.env, {
			scope: "chat_stream_hard_user_or_ip",
			identifier: user.id || ip,
			limit: 40,
			windowSec: 60,
		});
		if (hardRpmLimit.limited) {
			await logSafety({
				type: "rpm_limit_rejection",
				code: "HARD_RPM_LIMIT",
				message: "Hard per-minute stream request ceiling reached.",
				details: { limit: hardRpmLimit.limit, windowSec: hardRpmLimit.windowSec },
			});
			return rateLimited(c, "Too many streaming requests. Please wait a moment.", hardRpmLimit);
		}

		const ipLimit = await consumeRateLimit(c.env, {
			scope: "chat_stream_ip",
			identifier: ip,
			limit: 45,
			windowSec: 60,
		});
		if (ipLimit.limited) {
			await logSafety({
				type: "rpm_limit_rejection",
				code: "IP_RATE_LIMIT",
				message: "IP rate limit exceeded for chat stream.",
				details: { limit: ipLimit.limit, windowSec: ipLimit.windowSec },
			});
			return rateLimited(c, "Too many streaming requests from this IP.", ipLimit);
		}
		const userLimit = await consumeRateLimit(c.env, {
			scope: "chat_stream_user",
			identifier: user.id,
			limit: 30,
			windowSec: 60,
		});
		if (userLimit.limited) {
			await logSafety({
				type: "rpm_limit_rejection",
				code: "USER_RATE_LIMIT",
				message: "User rate limit exceeded for chat stream.",
				details: { limit: userLimit.limit, windowSec: userLimit.windowSec },
			});
			return rateLimited(c, "Too many streaming requests for this account.", userLimit);
		}

		const data = await this.getValidatedData<typeof this.schema>();
		const quota = await checkStreamQuota(c.env, user.id);
		if (quota.limited) {
			await logSafety({
				type: "quota_exhaustion",
				code: quota.code ?? "STREAM_QUOTA",
				message: quota.message ?? "Stream quota exhausted.",
				details: { requests: quota.requests, outputChars: quota.outputChars },
			});
			return jsonError(c, 429, quota.message, quota.code);
		}
		const chat = data.body.chatId ? await getChat(user, c.env, data.body.chatId) : null;
		if (data.body.chatId && !chat) return jsonError(c, 404, "Chat not found.");

		// TABAI composite model — smart routing
		const isTabai = isTabaiModel(data.body.model);
		let tabaiRoute: { actualModelId: string; routeReason: string } | null = null;
		const model = isTabai
			? tabaiVirtualModel()
			: await getAccessibleModelById(user, c.env, data.body.model);
		if (!model || !model.enabled) return jsonError(c, 404, "Model not found.");
		if (model.canAccess === false) {
			await logSafety({
				type: "expensive_model_violation",
				modelId: model.id,
				planTier: user.planTier,
				code: "MODEL_LOCKED",
				message: model.lockReason ?? "Model is not available for your plan.",
			});
			return jsonError(c, 403, model.lockReason ?? "Model is not available for your plan.", "MODEL_LOCKED");
		}
		if (model.supportsTextChat === false) {
			return jsonError(c, 400, "Selected model is not chat-compatible in this app.", "MODEL_NOT_CHAT_CAPABLE");
		}
		const expensiveModelDecision = enforceExpensiveModelAccess(c.env, {
			planTier: user.planTier,
			model,
		});
		if (!expensiveModelDecision.allowed) {
			const rejectedRequestId = crypto.randomUUID();
			await recordStreamLedgerRejection(c.env, {
				requestId: rejectedRequestId,
				userId: user.id,
				modelId: model.id,
				endpoint: "/api/chat/stream",
				planTier: user.planTier,
				estimatedInputTokens: 0,
				reservedOutputTokens: 0,
				estimatedTotalTokens: 0,
				estimatedCostUnits: 0,
				status: expensiveModelDecision.reason === "kill_switch" ? "rejected_kill_switch" : "rejected_model_allowlist",
			});
			await logSafety({
				type: expensiveModelDecision.reason === "kill_switch" ? "kill_switch_triggered" : "expensive_model_violation",
				requestId: rejectedRequestId,
				modelId: model.id,
				planTier: user.planTier,
				code: expensiveModelDecision.code ?? "EXPENSIVE_MODEL_BLOCKED",
				message: expensiveModelDecision.message ?? "Expensive model access denied.",
			});
			if (expensiveModelDecision.reason === "kill_switch") {
				return jsonError(c, 503, expensiveModelDecision.message ?? "Expensive models are temporarily disabled.", expensiveModelDecision.code ?? "DEGRADED_MODE");
			}
			return jsonError(c, 403, expensiveModelDecision.message ?? "This model requires a higher plan tier.", expensiveModelDecision.code ?? "UPGRADE_REQUIRED_EXPENSIVE_MODEL");
		}
		// ── Per-category daily chat message limit ──
		// Increment count immediately after check passes (before streaming) to prevent
		// cancellation bypass where a user cancels mid-stream to avoid the count.
		if (!isTabai && model.category) {
			const catQuota = await checkChatCategoryQuota(c.env, user.id, user.planTier, model.category);
			if (catQuota.allowed === false) {
				await logSafety({
					type: "quota_exhaustion",
					code: catQuota.code,
					message: catQuota.message,
					modelId: model.id,
					planTier: user.planTier,
					details: { category: model.category, used: catQuota.used, limit: catQuota.limit },
				});
				return jsonError(c, 429 as const, catQuota.message, catQuota.code);
			}
			// Reserve the slot immediately — don't wait for stream completion
			await incrementChatCategoryCount(c.env, user.id, model.category);
		}

		const attachments = (data.body.attachments ?? []) as StreamAttachment[];
		const hasImageAttachments = attachments.some((item) => item.type === "image_url");
		if (hasImageAttachments && !model.supportsVision) {
			return jsonError(c, 400, "Selected model does not support image inputs.", "MODEL_VISION_REQUIRED");
		}
		const inputMessageCount = data.body.messages.length;
		const inputChars = data.body.messages.reduce((total, message) => total + message.content.length, 0);
		const maxTokensRequested = data.body.maxTokens ?? 1024;
		const outputCharCap = streamOutputCharLimit(c.env);
		const upstreamMessages = applyAttachmentsToMessages(data.body.messages, attachments);
		const estimatedInputTokens = estimateTokensForMessages(upstreamMessages);
		const promptGuard = applyHardPromptGuard(c.env, estimatedInputTokens);
		if (!promptGuard.allowed) {
			const rejectedRequestId = crypto.randomUUID();
			await recordStreamLedgerRejection(c.env, {
				requestId: rejectedRequestId,
				userId: user.id,
				modelId: model.id,
				endpoint: "/api/chat/stream",
				planTier: user.planTier,
				estimatedInputTokens,
				reservedOutputTokens: 0,
				estimatedTotalTokens: estimatedInputTokens,
				estimatedCostUnits: estimateCostUnits(model, estimatedInputTokens),
				status: "rejected_prompt_limit",
			});
			await logSafety({
				type: "prompt_limit_rejection",
				requestId: rejectedRequestId,
				modelId: model.id,
				planTier: user.planTier,
				code: promptGuard.code ?? "HARD_PROMPT_TOKEN_LIMIT",
				message: promptGuard.message ?? "Prompt exceeds absolute token safety limit.",
				details: { estimatedPromptTokens: estimatedInputTokens, limit: promptGuard.limit },
			});
			return jsonError(c, 413, promptGuard.message ?? "Prompt exceeds absolute token safety limit.", promptGuard.code ?? "HARD_PROMPT_TOKEN_LIMIT");
		}
		const tokenGuard = applyRequestTokenGuard(c.env, user.planTier, estimatedInputTokens, maxTokensRequested);
		if (!tokenGuard.allowed) {
			await logSafety({
				type: "completion_limit_rejection",
				modelId: model.id,
				planTier: user.planTier,
				code: tokenGuard.code ?? "REQUEST_TOKEN_LIMIT_EXCEEDED",
				message: tokenGuard.message ?? "Estimated request size exceeds your plan allowance.",
				details: {
					estimatedInputTokens,
					requestedOutputTokens: maxTokensRequested,
					allowance: tokenGuard.allowance,
				},
			});
			return jsonError(c, 403, tokenGuard.message, tokenGuard.code);
		}
		const hardCompletionLimit = hardCompletionTokenLimit(c.env);
		const resolvedMaxTokens = Math.max(1, Math.min(tokenGuard.resolvedMaxTokens, hardCompletionLimit));
		const estimatedTotalTokens = estimatedInputTokens + resolvedMaxTokens;
		const estimatedCostUnits = estimateCostUnits(model, estimatedTotalTokens);
		const rollingBudget = await checkRollingUsageBudget(c.env, {
			userId: user.id,
			planTier: user.planTier,
			projectedTokens: estimatedTotalTokens,
			projectedCostUnits: estimatedCostUnits,
		});
		if (rollingBudget.limited) {
			await logSafety({
				type: "quota_exhaustion",
				modelId: model.id,
				planTier: user.planTier,
				code: rollingBudget.code ?? "ROLLING_USAGE_LIMIT",
				message: rollingBudget.message ?? "Daily usage budget reached.",
			});
			return jsonError(c, 429, rollingBudget.message ?? "Daily usage budget reached.", rollingBudget.code ?? "ROLLING_USAGE_LIMIT");
		}
		const spendCircuit = await checkGlobalSpendCircuit(c.env, estimatedCostUnits);
		if (spendCircuit.limited) {
			await logSafety({
				type: "quota_exhaustion",
				modelId: model.id,
				planTier: user.planTier,
				code: spendCircuit.code ?? "GLOBAL_SPEND_GUARD",
				message: spendCircuit.message ?? "Temporary capacity protection is active.",
				details: {
					totalEstimatedCostUnits: spendCircuit.totalEstimatedCostUnits,
					limit: spendCircuit.limit,
				},
			});
			return jsonError(c, 503, spendCircuit.message ?? "Temporary capacity protection is active.", spendCircuit.code ?? "GLOBAL_SPEND_GUARD");
		}
		const lease = await acquireStreamLease(c.env, user.id, user.planTier);
		if (lease.limited || !lease.leaseId) {
			await logSafety({
				type: "stream_concurrency_rejection",
				modelId: model.id,
				planTier: user.planTier,
				code: lease.code ?? "CONCURRENT_STREAM_LIMIT",
				message: lease.message ?? "Too many active streams.",
				details: { active: lease.active, limit: lease.limit },
			});
			return jsonError(c, 429, lease.message ?? "Too many active streams.", lease.code ?? "CONCURRENT_STREAM_LIMIT");
		}
		const streamRequestId = crypto.randomUUID();
		const reservation = await reserveDailyCostLedgerStart(c.env, {
			requestId: streamRequestId,
			userId: user.id,
			modelId: model.id,
			endpoint: "/api/chat/stream",
			planTier: user.planTier,
			estimatedInputTokens,
			reservedOutputTokens: resolvedMaxTokens,
			estimatedTotalTokens,
			estimatedCostUnits,
		});
		if (!reservation.reserved) {
			await releaseStreamLease(c.env, lease.leaseId);
			await logSafety({
				type: "daily_cost_cap_exhausted",
				requestId: streamRequestId,
				modelId: model.id,
				planTier: user.planTier,
				code: reservation.code ?? "DAILY_HARD_COST_CAP",
				message: reservation.message ?? "Daily hard cost cap reached for this account.",
				details: { used: reservation.used, projected: reservation.projected, limit: reservation.limit },
			});
			return jsonError(c, 429, reservation.message ?? "Daily hard cost cap reached for this account.", reservation.code ?? "DAILY_HARD_COST_CAP");
		}

		// Resolve actual model for TABAI composite routing
		if (isTabai) {
			tabaiRoute = routeTabaiModel(data.body.messages as Array<{ role: string; content: string }>);
		}
		const upstreamModelId = isTabai && tabaiRoute ? tabaiRoute.actualModelId : model.providerModelId;

		const upstream = await streamOpenRouter(c.env, upstreamModelId, upstreamMessages, resolvedMaxTokens);
		if (!upstream.ok || !upstream.body) {
			const text = await upstream.text();
			await recordStreamLedgerFinalize(c.env, {
				requestId: streamRequestId,
				status: "upstream_error",
				actualOutputChars: 0,
			});
			await releaseStreamLease(c.env, lease.leaseId);
			await recordUsageEvent(c.env, {
				userId: user.id,
				chatId: chat?.id ?? null,
				modelId: model.id,
				endpoint: "/api/chat/stream",
				inputMessageCount,
				inputChars,
				maxTokensRequested: resolvedMaxTokens,
				outputChars: 0,
				status: "upstream_error",
				finishReason: null,
				ip,
			});
			return jsonError(c, upstream.status || 502, text || "Upstream stream failed.");
		}

		const encoder = new TextEncoder();
		const decoder = new TextDecoder();
		let output = "";
		let finishReason = "stop";
		let finished = false;
		const finalizeStream = async (status: "completed" | "truncated" | "upstream_error" | "client_error") => {
			if (finished) return;
			finished = true;
			await recordStreamLedgerFinalize(c.env, {
				requestId: streamRequestId,
				status,
				actualOutputChars: output.length,
			});
			await releaseStreamLease(c.env, lease.leaseId);
		};
		const stream = new ReadableStream<Uint8Array>({
			async start(controller) {
				const reader = upstream.body!.getReader();
				let buffer = "";
				controller.enqueue(encoder.encode(sseEvent("start", { ok: true, chatId: chat?.id ?? null })));
				if (isTabai && tabaiRoute) {
					controller.enqueue(encoder.encode(sseEvent("metadata", { poweredBy: tabaiRoute.actualModelId, routeReason: tabaiRoute.routeReason })));
				}
				const persist = async (status: "completed" | "truncated" | "client_error" = "completed") => {
					if (finished) return;
					await finalizeStream(status);
					const message = chat && output.trim()
						? await createMessage(user, c.env, chat.id, { role: "assistant", content: output })
						: null;
					await recordUsageEvent(c.env, {
						userId: user.id,
						chatId: chat?.id ?? null,
						modelId: model.id,
						endpoint: "/api/chat/stream",
						inputMessageCount,
						inputChars,
						maxTokensRequested: resolvedMaxTokens,
						outputChars: output.length,
						status,
						finishReason,
						ip,
					});
					// Category count was already incremented before stream started (pre-reservation)
					if (chat?.id) void (invalidateUserCaches(c, user.id));
					controller.enqueue(
						encoder.encode(
							sseEvent("done", {
								finishReason,
								chatId: chat?.id ?? null,
								messageId: message?.id ?? null,
							}),
						),
					);
					controller.close();
				};
				try {
					while (true) {
						const { done, value } = await reader.read();
						if (done) break;
						buffer += decoder.decode(value, { stream: true });
						let boundary = buffer.indexOf("\n\n");
						while (boundary >= 0) {
							const block = buffer.slice(0, boundary);
							buffer = buffer.slice(boundary + 2);
							const dataLine = block
								.split("\n")
								.map((line) => line.replace(/\r$/, ""))
								.filter((line) => line.startsWith("data:"))
								.map((line) => line.slice(5).trim())
								.join("\n");
							if (!dataLine) {
								boundary = buffer.indexOf("\n\n");
								continue;
							}
							if (dataLine === "[DONE]") {
								await persist();
								return;
							}
							const payload = JSON.parse(dataLine);
							if (typeof payload?.choices?.[0]?.finish_reason === "string") {
								finishReason = payload.choices[0].finish_reason;
							}
							const delta = payload?.choices?.[0]?.delta?.content;
							if (typeof delta === "string" && delta.length > 0) {
								output += delta;
								controller.enqueue(encoder.encode(sseEvent("token", { delta })));
								const estimatedOutputTokens = Math.ceil(output.length / 4);
								if (estimatedOutputTokens >= hardCompletionLimit) {
									finishReason = "length";
									void (logSafety({
										type: "stream_truncated",
										requestId: streamRequestId,
										modelId: model.id,
										planTier: user.planTier,
										code: "HARD_COMPLETION_TOKEN_LIMIT",
										message: "Stream truncated at hard completion token limit.",
										details: { estimatedOutputTokens, hardCompletionLimit },
									}));
									await reader.cancel();
									await persist("truncated");
									return;
								}
								if (output.length >= outputCharCap) {
									finishReason = "length";
									void (logSafety({
										type: "stream_truncated",
										requestId: streamRequestId,
										modelId: model.id,
										planTier: user.planTier,
										code: "STREAM_OUTPUT_CHAR_LIMIT",
										message: "Stream truncated at output character safety limit.",
										details: { outputChars: output.length, outputCharCap },
									}));
									await reader.cancel();
									await persist("truncated");
									return;
								}
							}
							boundary = buffer.indexOf("\n\n");
						}
					}
					await persist();
				} catch (error) {
					finishReason = "error";
					void finalizeStream("client_error");
					void recordUsageEvent(c.env, {
						userId: user.id,
						chatId: chat?.id ?? null,
						modelId: model.id,
						endpoint: "/api/chat/stream",
						inputMessageCount,
						inputChars,
						maxTokensRequested: resolvedMaxTokens,
						outputChars: output.length,
						status: "client_error",
						finishReason,
						ip,
					});
					controller.enqueue(encoder.encode(sseEvent("error", { error: error instanceof Error ? error.message : "Streaming failed." })));
					controller.close();
				}
			},
			async cancel() {
				if (finished) return;
				finishReason = "cancelled";
				await finalizeStream("client_error");
			},
		});
		applyCors(c);
		c.header("Content-Type", "text/event-stream");
		c.header("Cache-Control", "no-cache");
		c.header("Connection", "keep-alive");
		return new Response(stream, { headers: c.res.headers });
	}
}

export class AdminUsersRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "List users",
		responses: { "200": { description: "Users", content: { "application/json": { schema: z.object({ users: z.array(UserSchema) }) } } } },
	};
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		return c.json({ users: await listUsers(c.env) });
	}
}

export class AdminUsersCreateRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "Create user",
		request: { body: { content: { "application/json": { schema: AdminUserCreateBody } } } },
		responses: { "201": { description: "Created", content: { "application/json": { schema: z.object({ user: UserSchema }) } } } },
	};
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const user = await createUser(c.env, admin.user, data.body);
		applyCors(c);
		return c.json({ user }, 201);
	}
}

export class AdminUserPatchRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "Update user",
		request: { params: UserIdParam, body: { content: { "application/json": { schema: AdminUserPatchBody } } } },
		responses: { "200": { description: "Updated", content: { "application/json": { schema: z.object({ user: UserSchema }) } } } },
	};
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const user = await patchUser(c.env, admin.user, data.params.userId, data.body);
		if (!user) return jsonError(c, 404, "User not found.");
		applyCors(c);
		return c.json({ user });
	}
}

export class AdminUserEntitlementGetRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "Get user entitlement",
		request: { params: UserIdParam },
		responses: {
			"200": {
				description: "Entitlement",
				content: {
					"application/json": {
						schema: z.object({ effective: EntitlementSchema.nullable(), latest: EntitlementSchema.nullable() }),
					},
				},
			},
		},
	};

	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		const data = await this.getValidatedData<typeof this.schema>();
		const entitlement = await getUserEntitlement(c.env, data.params.userId);
		applyCors(c);
		return c.json(entitlement);
	}
}

export class AdminUserEntitlementPutRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "Set user entitlement override",
		request: {
			params: UserIdParam,
			body: { content: { "application/json": { schema: AdminEntitlementPatchBody } } },
		},
		responses: {
			"200": {
				description: "Updated entitlement",
				content: {
					"application/json": {
						schema: z.object({ entitlement: EntitlementSchema.nullable(), user: UserSchema.nullable() }),
					},
				},
			},
		},
	};

	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const entitlement = await setAdminUserEntitlement(c.env, admin.user, data.params.userId, data.body);
		if (!entitlement) return jsonError(c, 404, "User not found.");
		const user = await getUserById(c.env, data.params.userId);
		applyCors(c);
		return c.json({ entitlement, user });
	}
}

export class AdminUserDeleteRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Delete user", request: { params: UserIdParam }, responses: { "200": { description: "Deleted" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		await removeUser(c.env, admin.user, data.params.userId);
		applyCors(c);
		return c.json({ ok: true });
	}
}

export class AdminPermissionsGetRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "Get user permissions",
		request: { params: UserIdParam },
		responses: { "200": { description: "Permissions", content: { "application/json": { schema: z.object({ models: z.array(ModelSchema.extend({ canAccess: z.boolean().optional() })) }) } } } },
	};
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		return c.json({ models: await getUserPermissions(c.env, admin.user, data.params.userId) });
	}
}

export class AdminPermissionsPutRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "Save user permissions",
		request: { params: UserIdParam, body: { content: { "application/json": { schema: PermissionsBody } } } },
		responses: { "200": { description: "Saved" } },
	};
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		await saveUserPermissions(c.env, admin.user, data.params.userId, data.body.modelIds);
		applyCors(c);
		void (invalidateUserCaches(c, data.params.userId));
		return c.json({ ok: true });
	}
}

export class AdminModelsRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "List models",
		responses: { "200": { description: "Models", content: { "application/json": { schema: z.object({ models: z.array(ModelSchema) }) } } } },
	};
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		return c.json({ models: await listAdminModels(c.env) });
	}
}

export class AdminModelsPostRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "Create model or sync OpenRouter",
		request: { body: { content: { "application/json": { schema: AdminModelPostBody } } } },
		responses: { "200": { description: "Result" } },
	};
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		if (data.body.action === "sync-openrouter") {
			await syncModelsIfNeeded(c.env, true);
			await logAudit(c.env, admin.user, "model.sync", "provider", "openrouter", null);
			return c.json({ ok: true });
		}
		const model = await createAdminModel(c.env, admin.user, data.body);
		return c.json({ model }, 201);
	}
}

export class AdminModelPatchRoute extends OpenAPIRoute {
	schema = {
		tags: ["Admin"],
		summary: "Update model",
		request: { params: ModelIdParam, body: { content: { "application/json": { schema: AdminModelPatchBody } } } },
		responses: { "200": { description: "Updated" } },
	};
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		const model = await patchAdminModel(c.env, admin.user, data.params.modelId, data.body);
		if (!model) return jsonError(c, 404, "Model not found.");
		applyCors(c);
		return c.json({ model });
	}
}

export class AdminProvidersRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "List providers", responses: { "200": { description: "Providers" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		return c.json({ providers: await listAdminProviders(c.env) });
	}
}

export class AdminProviderPatchRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Update provider", request: { params: ProviderIdParam, body: { content: { "application/json": { schema: z.object({ enabled: z.boolean().optional(), endpointUrl: z.string().optional() }) } } } }, responses: { "200": { description: "Updated" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		applyCors(c);
		return c.json({ ok: true });
	}
}

export class AdminChatsRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "List chats", responses: { "200": { description: "Chats" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		return c.json({ chats: await listAdminChats(c.env) });
	}
}

export class AdminAuditRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Audit log", responses: { "200": { description: "Audit" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		return c.json({ entries: await listAudit(c.env) });
	}
}

// ── Analytics ──

export class AdminOverviewRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Dashboard overview stats", responses: { "200": { description: "Overview" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		return c.json(await getAdminOverviewStats(c.env));
	}
}

export class AdminUserGrowthRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "User growth over time", responses: { "200": { description: "Growth" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		const days = parseInt(new URL(c.req.url).searchParams.get("days") ?? "30");
		return c.json({ growth: await getAdminUserGrowth(c.env, days) });
	}
}

export class AdminModelUsageRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Model usage stats", responses: { "200": { description: "Usage" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		const days = parseInt(new URL(c.req.url).searchParams.get("days") ?? "7");
		return c.json({ usage: await getAdminModelUsage(c.env, days) });
	}
}

export class AdminRevenueRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Revenue breakdown", responses: { "200": { description: "Revenue" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		return c.json({ revenue: await getAdminRevenueBreakdown(c.env) });
	}
}

export class AdminErrorSummaryRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Error summary", responses: { "200": { description: "Errors" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		const days = parseInt(new URL(c.req.url).searchParams.get("days") ?? "7");
		return c.json({ errors: await getAdminErrorSummary(c.env, days) });
	}
}

export class AdminSafetyEventsRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Safety events", responses: { "200": { description: "Events" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		const url = new URL(c.req.url);
		const limit = parseInt(url.searchParams.get("limit") ?? "100");
		const offset = parseInt(url.searchParams.get("offset") ?? "0");
		return c.json({ events: await getAdminSafetyEvents(c.env, limit, offset) });
	}
}

// ── User details ──

export class AdminUserChatsRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "User chats", request: { params: z.object({ userId: z.string() }) }, responses: { "200": { description: "Chats" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		return c.json({ chats: await getAdminUserChats(c.env, data.params.userId) });
	}
}

export class AdminUserUsageRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "User usage", request: { params: z.object({ userId: z.string() }) }, responses: { "200": { description: "Usage" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		const user = await getUserById(c.env, data.params.userId);
		if (!user) return jsonError(c, 404, "User not found");
		return c.json(await getUserUsageSnapshot(c.env, user.id, user.planTier));
	}
}

// ── Admin notes ──

export class AdminNotesGetRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Get user notes", request: { params: z.object({ userId: z.string() }) }, responses: { "200": { description: "Notes" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		return c.json({ notes: await listAdminNotes(c.env, data.params.userId) });
	}
}

export class AdminNotesPostRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Create user note", request: { params: z.object({ userId: z.string() }), body: { content: { "application/json": { schema: z.object({ content: z.string().min(1) }) } } } }, responses: { "201": { description: "Created" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		const result = await createAdminNote(c.env, data.params.userId, admin.user.id, data.body.content);
		return c.json(result, 201);
	}
}

// ── Discount codes ──

export class AdminDiscountCodesGetRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "List discount codes", responses: { "200": { description: "Codes" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		return c.json({ codes: await listDiscountCodes(c.env) });
	}
}

export class AdminDiscountCodesPostRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Create discount code", request: { body: { content: { "application/json": { schema: z.object({ code: z.string().min(3), planTier: z.string(), durationDays: z.number().min(1), maxUses: z.number().min(1).default(1), expiresAt: z.string().optional() }) } } } }, responses: { "201": { description: "Created" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		const result = await createDiscountCode(c.env, data.body as any, admin.user.id);
		return c.json(result, 201);
	}
}

export class AdminDiscountCodesDeleteRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "Deactivate discount code", request: { params: z.object({ codeId: z.string() }) }, responses: { "200": { description: "OK" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		await deleteDiscountCode(c.env, data.params.codeId);
		return c.json({ ok: true });
	}
}

// ── Redeem (user-facing) ──

export class RedeemCodeRoute extends OpenAPIRoute {
	schema = { tags: ["Codes"], summary: "Redeem discount code", request: { body: { content: { "application/json": { schema: z.object({ code: z.string().min(1) }) } } } }, responses: { "200": { description: "Result" } } };
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		const data = await this.getValidatedData<typeof this.schema>();
		applyCors(c);
		const result = await redeemDiscountCode(c.env, user, data.body.code);
		if ("error" in result) return jsonError(c, 400, result.error);
		return c.json(result);
	}
}

// ── System health ──

export class AdminSystemHealthRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "System health", responses: { "200": { description: "Health" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		return c.json(await getSystemHealth(c.env));
	}
}

// ── Enhanced user listing ──

export class AdminUsersPaginatedRoute extends OpenAPIRoute {
	schema = { tags: ["Admin"], summary: "List users paginated", responses: { "200": { description: "Users" } } };
	async handle(c: AppContext) {
		const admin = await requireAdmin(c);
		if ("error" in admin) return admin.error;
		applyCors(c);
		const url = new URL(c.req.url);
		return c.json(await listUsersPaginated(c.env, {
			search: url.searchParams.get("search") ?? undefined,
			planTier: url.searchParams.get("planTier") ?? undefined,
			status: url.searchParams.get("status") ?? undefined,
			page: parseInt(url.searchParams.get("page") ?? "1"),
			limit: parseInt(url.searchParams.get("limit") ?? "50"),
		}));
	}
}

// ══════════════════════════════════════════════════════════════════
// FAL.AI GENERATION ENDPOINTS
// ══════════════════════════════════════════════════════════════════

const GenerateImageBody = z.object(falGenerateImageSchema.shape);
const GenerateVideoBody = z.object(falGenerateVideoSchema.shape);
const GenerationIdParam = z.object({ id: Str() });

export class GenerateImageRoute extends OpenAPIRoute {
	schema = {
		tags: ["Generate"],
		summary: "Submit image generation",
		request: { body: { content: { "application/json": { schema: GenerateImageBody } } } },
		responses: {
			"202": { description: "Generation queued", content: { "application/json": { schema: z.object({ id: Str(), status: Str() }) } } },
			"403": { description: "Plan limit" },
			"429": { description: "Rate limited" },
		},
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		applyCors(c);

		const data = await this.getValidatedData<typeof this.schema>();
		const { prompt, negativePrompt, modelId, chatId, imageSize, numImages, style } = data.body;

		const modelInfo = getFalModelInfo(modelId);
		if (!modelInfo || modelInfo.generationType !== "image") return jsonError(c, 400, "Invalid image model.");

		// Global circuit breaker
		const globalCheck = await globalFalSpendCheck(c.env);
		if (!globalCheck.allowed) {
			const msg = (globalCheck as { message: string }).message;
			await recordSafetyEvent(c.env, { type: "fal_global_circuit", userId: user.id, ip: getClientIp(c), code: "FAL_GLOBAL_CIRCUIT", message: msg });
			return jsonError(c, 503, msg);
		}

		// Per-user budget
		const budgetCheck = await checkFalBudget(c.env, user.id, user.planTier, "image", modelId);
		if (!budgetCheck.allowed) {
			const bc = budgetCheck as { code: string; message: string };
			await recordSafetyEvent(c.env, { type: "fal_budget_rejection", userId: user.id, ip: getClientIp(c), code: bc.code, message: bc.message, planTier: user.planTier });
			return jsonError(c, 429, bc.message);
		}

		const params: Record<string, unknown> = {};
		if (imageSize) params.image_size = imageSize;
		if (numImages) params.num_images = numImages;
		if (style) params.style = style;

		const result = await submitFalGeneration(c.env, user.id, chatId ?? null, modelId, prompt, negativePrompt ?? null, params);
		if ("error" in result) {
			await recordSafetyEvent(c.env, { type: "fal_error", userId: user.id, ip: getClientIp(c), code: "FAL_SUBMIT_ERROR", message: result.error, modelId });
			return jsonError(c, 502, result.error);
		}

		return c.json({ id: result.id, falRequestId: result.falRequestId, status: "queued" } as const, 202 as const);
	}
}

export class GenerateVideoRoute extends OpenAPIRoute {
	schema = {
		tags: ["Generate"],
		summary: "Submit video generation",
		request: { body: { content: { "application/json": { schema: GenerateVideoBody } } } },
		responses: {
			"202": { description: "Generation queued", content: { "application/json": { schema: z.object({ id: Str(), status: Str() }) } } },
			"403": { description: "Plan limit" },
			"429": { description: "Rate limited" },
		},
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		applyCors(c);

		const data = await this.getValidatedData<typeof this.schema>();
		const { prompt, negativePrompt, modelId, chatId, duration, resolution, imageUrl } = data.body;

		const modelInfo = getFalModelInfo(modelId);
		if (!modelInfo || (modelInfo.generationType !== "video" && modelInfo.generationType !== "image_to_video")) {
			return jsonError(c, 400, "Invalid video model.");
		}

		if (modelInfo.generationType === "image_to_video" && !imageUrl) {
			return jsonError(c, 400, "imageUrl is required for image-to-video models.");
		}

		const globalCheck = await globalFalSpendCheck(c.env);
		if (!globalCheck.allowed) {
			const msg = (globalCheck as { message: string }).message;
			await recordSafetyEvent(c.env, { type: "fal_global_circuit", userId: user.id, ip: getClientIp(c), code: "FAL_GLOBAL_CIRCUIT", message: msg });
			return jsonError(c, 503, msg);
		}

		const budgetCheck = await checkFalBudget(c.env, user.id, user.planTier, modelInfo.generationType, modelId);
		if (!budgetCheck.allowed) {
			const bc = budgetCheck as { code: string; message: string };
			await recordSafetyEvent(c.env, { type: "fal_budget_rejection", userId: user.id, ip: getClientIp(c), code: bc.code, message: bc.message, planTier: user.planTier });
			return jsonError(c, 429, bc.message);
		}

		const params: Record<string, unknown> = {};
		if (duration) params.duration = duration;
		if (resolution) params.resolution = resolution;
		if (imageUrl) params.image_url = imageUrl;

		const result = await submitFalGeneration(c.env, user.id, chatId ?? null, modelId, prompt, negativePrompt ?? null, params);
		if ("error" in result) {
			await recordSafetyEvent(c.env, { type: "fal_error", userId: user.id, ip: getClientIp(c), code: "FAL_SUBMIT_ERROR", message: result.error, modelId });
			return jsonError(c, 502, result.error);
		}

		return c.json({ id: result.id, falRequestId: result.falRequestId, status: "queued" } as const, 202 as const);
	}
}

export class GenerateStatusRoute extends OpenAPIRoute {
	schema = {
		tags: ["Generate"],
		summary: "Poll generation status",
		request: { params: GenerationIdParam },
		responses: { "200": { description: "Status" } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);

		const data = await this.getValidatedData<typeof this.schema>();
		const gen = await getGenerationById(c.env, user.id, data.params.id);
		if (!gen) return jsonError(c, 404, "Generation not found.");

		// If still in progress, poll fal.ai for live status
		// 'reserving' is a transient state during atomic budget reservation (becomes 'queued' within ms)
		if (gen.status === "queued" || gen.status === "processing" || gen.status === "reserving") {
			// Extract fal.ai canonical URLs stored at submit time
			let falStatusUrl: string | null = null;
			let falResponseUrl: string | null = null;
			try {
				const p = gen.parameters ? JSON.parse(gen.parameters) : {};
				falStatusUrl = p._fal_status_url ?? null;
				falResponseUrl = p._fal_response_url ?? null;
			} catch {}

			const falStatus = await checkFalStatus(c.env, gen.falRequestId, gen.modelId, falStatusUrl);
			const newStatus = falStatus.status === "COMPLETED" ? "completed"
				: falStatus.status === "FAILED" ? "failed"
				: falStatus.status === "IN_PROGRESS" ? "processing"
				: gen.status;

			if (newStatus === "completed") {
				const resultData = await getFalResult(c.env, gen.falRequestId, gen.modelId, falResponseUrl);
				if ("data" in resultData) {
					const images = resultData.data.images as Array<{ url: string }> | undefined;
					const video = resultData.data.video as { url: string } | undefined;
					const resultUrl = images?.[0]?.url ?? video?.url ?? null;
					await updateGenerationStatus(c.env, gen.id, "completed", resultUrl, resultData.data);
					return c.json({ id: gen.id, status: "completed", resultUrl, metadata: resultData.data });
				}
			} else if (newStatus === "failed") {
				await updateGenerationStatus(c.env, gen.id, "failed", null, null, "Generation failed on fal.ai");
				return c.json({ id: gen.id, status: "failed", errorMessage: "Generation failed on fal.ai" });
			} else if (newStatus !== gen.status) {
				await updateGenerationStatus(c.env, gen.id, newStatus as any);
			}

			return c.json({ id: gen.id, status: newStatus, queuePosition: falStatus.queuePosition ?? null });
		}

		return c.json({
			id: gen.id,
			status: gen.status,
			resultUrl: gen.resultUrl,
			metadata: gen.resultMetadata ? JSON.parse(gen.resultMetadata) : null,
			errorMessage: gen.errorMessage,
		});
	}
}

export class GenerateGetRoute extends OpenAPIRoute {
	schema = {
		tags: ["Generate"],
		summary: "Get generation result",
		request: { params: GenerationIdParam },
		responses: { "200": { description: "Generation" } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);

		const data = await this.getValidatedData<typeof this.schema>();
		const gen = await getGenerationById(c.env, user.id, data.params.id);
		if (!gen) return jsonError(c, 404, "Generation not found.");

		return c.json({
			...gen,
			parameters: gen.parameters ? JSON.parse(gen.parameters) : null,
			resultMetadata: gen.resultMetadata ? JSON.parse(gen.resultMetadata) : null,
		});
	}
}

export class GenerateQuotaRoute extends OpenAPIRoute {
	schema = {
		tags: ["Generate"],
		summary: "Get generation quota for current user",
		responses: { "200": { description: "Quota snapshot" } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);
		c.header("Cache-Control", "no-store");
		const snapshot = await getFalQuotaSnapshot(c.env, user.id, user.planTier);
		return c.json(snapshot);
	}
}

export class ChatQuotaRoute extends OpenAPIRoute {
	schema = {
		tags: ["Chats"],
		summary: "Get daily chat message quota per model category",
		responses: { "200": { description: "Chat quota snapshot" } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);
		c.header("Cache-Control", "no-store");
		const limits = CHAT_TIER_LIMITS[user.planTier];

		const categories = Object.keys(limits) as (keyof typeof limits)[];
		const result: Record<string, { used: number; limit: number; remaining: number }> = {};
		for (const cat of categories) {
			const limit = limits[cat];
			if (limit <= 0) {
				result[cat] = { used: 0, limit: 0, remaining: 0 };
				continue;
			}
			const quota = await checkChatCategoryQuota(c.env, user.id, user.planTier, cat as ModelCategory);
			result[cat] = { used: quota.used, limit: quota.limit, remaining: Math.max(0, quota.limit - quota.used) };
		}
		return c.json({ planTier: user.planTier, categories: result });
	}
}

export class GenerateHistoryRoute extends OpenAPIRoute {
	schema = {
		tags: ["Generate"],
		summary: "List generation history",
		responses: { "200": { description: "Generations" } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		applyCors(c);

		const url = new URL(c.req.url);
		const limit = Math.min(parseInt(url.searchParams.get("limit") ?? "50"), 100);
		const offset = parseInt(url.searchParams.get("offset") ?? "0");
		const generations = await listGenerations(c.env, user.id, limit, offset);
		return c.json({ generations });
	}
}

export class GenerateDeleteRoute extends OpenAPIRoute {
	schema = {
		tags: ["Generate"],
		summary: "Cancel generation",
		request: { params: GenerationIdParam },
		responses: { "200": { description: "Cancelled" } },
	};
	async handle(c: AppContext) {
		const user = await requireUser(c);
		if (!user) return authRequired(c);
		if (!validateCsrf(c)) return csrfRequired(c);
		applyCors(c);

		const data = await this.getValidatedData<typeof this.schema>();
		const ok = await cancelGeneration(c.env, user.id, data.params.id);
		if (!ok) return jsonError(c, 404, "Generation not found or cannot be cancelled.");
		return c.json({ ok: true, cancelled: data.params.id });
	}
}
