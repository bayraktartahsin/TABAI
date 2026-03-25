import { serve } from "@hono/node-server";
import { config } from "dotenv";
import Database from "better-sqlite3";
import path from "path";
import fs from "fs";
import { createD1Compat } from "./d1-compat";
import { fromHono } from "chanfana";
import { Hono } from "hono";
import {
	AdminAuditRoute,
	AdminChatsRoute,
	AdminModelPatchRoute,
	AdminModelsPostRoute,
	AdminModelsRoute,
	AdminPermissionsGetRoute,
	AdminPermissionsPutRoute,
	AdminProviderPatchRoute,
	AdminProvidersRoute,
	AdminUserDeleteRoute,
	AdminUserEntitlementGetRoute,
	AdminUserEntitlementPutRoute,
	AdminUsersCreateRoute,
	AdminUserPatchRoute,
	AdminUsersRoute,
	AuthMeRoute,
	AuthPasswordResetConfirmRoute,
	AuthPasswordResetRequestRoute,
	AuthSignupRoute,
	AuthSignInRoute,
	AuthSignOutRoute,
	AuthVerificationConfirmRoute,
	AuthVerificationRequestRoute,
	BootstrapRoute,
	ChatMessagesCreateRoute,
	ChatMessagesRoute,
	ChatsCreateRoute,
	ChatsDeleteRoute,
	ChatsPatchRoute,
	ChatsRoute,
	ChatStreamRoute,
	FoldersCreateRoute,
	FoldersDeleteRoute,
	FoldersListRoute,
	FoldersPatchRoute,
	HealthRoute,
	ModelsRoute,
	OptionsRoute,
	SettingsAccountPatchRoute,
	SettingsGetRoute,
	SettingsPatchRoute,
	StoreEntitlementSyncRoute,
	UsageRoute,
	AuthAppleRoute,
	AuthGoogleRoute,
	AuthGoogleCallbackRoute,
	AdminOverviewRoute,
	AdminUserGrowthRoute,
	AdminModelUsageRoute,
	AdminRevenueRoute,
	AdminErrorSummaryRoute,
	AdminSafetyEventsRoute,
	AdminUserChatsRoute,
	AdminUserUsageRoute,
	AdminNotesGetRoute,
	AdminNotesPostRoute,
	AdminDiscountCodesGetRoute,
	AdminDiscountCodesPostRoute,
	AdminDiscountCodesDeleteRoute,
	AdminSystemHealthRoute,
	AdminUsersPaginatedRoute,
	RedeemCodeRoute,
	GenerateImageRoute,
	GenerateVideoRoute,
	GenerateStatusRoute,
	GenerateGetRoute,
	GenerateHistoryRoute,
	GenerateDeleteRoute,
} from "./endpoints/tai";
import { preflight } from "./lib";

config();

// --- Initialize SQLite database ---
const dbPath = process.env.DB_PATH || path.join(process.cwd(), "data/tai.db");
fs.mkdirSync(path.dirname(dbPath), { recursive: true });
const sqlite = new Database(dbPath);
sqlite.pragma("journal_mode = WAL");
sqlite.pragma("foreign_keys = ON");
const db = createD1Compat(sqlite);

// --- Build Hono app (identical routes to index.ts) ---
const app = new Hono<{ Bindings: Env }>();

// Middleware: inject env bindings into every request context.
// In Workers, env comes from fetch(req, env, ctx). In Node.js, we set it here.
// Spread all process.env vars so envString(env, key) works for any secret
// (APPLE_APP_STORE_*, GOOGLE_CLIENT_*, TAI_BOOTSTRAP_*, TAI_STORE_*, etc.)
app.use("*", async (c, next) => {
	Object.assign(c.env, process.env);
	c.env.DB = db as any;
	await next();
});

const openapi = fromHono(app, { docs_url: "/docs" });

app.options("/api/*", (c) => preflight(c));

// --- Route registration (copied verbatim from index.ts lines 81-154) ---
openapi.get("/api/health", HealthRoute);
openapi.post("/api/auth/signin", AuthSignInRoute);
openapi.post("/api/auth/signup", AuthSignupRoute);
openapi.post("/api/auth/apple", AuthAppleRoute);
openapi.get("/api/auth/google", AuthGoogleRoute);
openapi.get("/api/auth/google/callback", AuthGoogleCallbackRoute);
openapi.post("/api/auth/verify/request", AuthVerificationRequestRoute);
openapi.post("/api/auth/verify/confirm", AuthVerificationConfirmRoute);
openapi.post("/api/auth/password-reset/request", AuthPasswordResetRequestRoute);
openapi.post("/api/auth/password-reset/confirm", AuthPasswordResetConfirmRoute);
openapi.get("/api/auth/me", AuthMeRoute);
openapi.post("/api/auth/signout", AuthSignOutRoute);
openapi.post("/api/entitlements/store/sync", StoreEntitlementSyncRoute);
openapi.get("/api/bootstrap", BootstrapRoute);
openapi.get("/api/models", ModelsRoute);
openapi.get("/api/chats", ChatsRoute);
openapi.post("/api/chats", ChatsCreateRoute);
openapi.patch("/api/chats/:id", ChatsPatchRoute);
openapi.delete("/api/chats/:id", ChatsDeleteRoute);
openapi.get("/api/chats/:chatId/messages", ChatMessagesRoute);
openapi.post("/api/chats/:chatId/messages", ChatMessagesCreateRoute);
openapi.post("/api/chat/stream", ChatStreamRoute);
openapi.get("/api/usage", UsageRoute);
openapi.get("/api/settings", SettingsGetRoute);
openapi.patch("/api/settings", SettingsPatchRoute);
openapi.patch("/api/settings/account", SettingsAccountPatchRoute);
openapi.get("/api/folders", FoldersListRoute);
openapi.post("/api/folders", FoldersCreateRoute);
openapi.patch("/api/folders/:folderId", FoldersPatchRoute);
openapi.delete("/api/folders/:folderId", FoldersDeleteRoute);
openapi.get("/api/admin/users", AdminUsersRoute);
openapi.post("/api/admin/users", AdminUsersCreateRoute);
openapi.patch("/api/admin/users/:userId", AdminUserPatchRoute);
openapi.get("/api/admin/users/:userId/entitlement", AdminUserEntitlementGetRoute);
openapi.put("/api/admin/users/:userId/entitlement", AdminUserEntitlementPutRoute);
openapi.delete("/api/admin/users/:userId", AdminUserDeleteRoute);
openapi.get("/api/admin/users/:userId/permissions", AdminPermissionsGetRoute);
openapi.put("/api/admin/users/:userId/permissions", AdminPermissionsPutRoute);
openapi.get("/api/admin/models", AdminModelsRoute);
openapi.post("/api/admin/models", AdminModelsPostRoute);
openapi.patch("/api/admin/models/:modelId", AdminModelPatchRoute);
openapi.get("/api/admin/providers", AdminProvidersRoute);
openapi.patch("/api/admin/providers/:providerId", AdminProviderPatchRoute);
openapi.get("/api/admin/chats", AdminChatsRoute);
openapi.get("/api/admin/audit", AdminAuditRoute);
// Analytics
openapi.get("/api/admin/analytics/overview", AdminOverviewRoute);
openapi.get("/api/admin/analytics/growth", AdminUserGrowthRoute);
openapi.get("/api/admin/analytics/model-usage", AdminModelUsageRoute);
openapi.get("/api/admin/analytics/revenue", AdminRevenueRoute);
openapi.get("/api/admin/analytics/errors", AdminErrorSummaryRoute);
openapi.get("/api/admin/safety-events", AdminSafetyEventsRoute);
// User details
openapi.get("/api/admin/users-search", AdminUsersPaginatedRoute);
openapi.get("/api/admin/users/:userId/chats", AdminUserChatsRoute);
openapi.get("/api/admin/users/:userId/usage", AdminUserUsageRoute);
openapi.get("/api/admin/users/:userId/notes", AdminNotesGetRoute);
openapi.post("/api/admin/users/:userId/notes", AdminNotesPostRoute);
// Discount codes
openapi.get("/api/admin/discount-codes", AdminDiscountCodesGetRoute);
openapi.post("/api/admin/discount-codes", AdminDiscountCodesPostRoute);
openapi.delete("/api/admin/discount-codes/:codeId", AdminDiscountCodesDeleteRoute);
// System
openapi.get("/api/admin/system/health", AdminSystemHealthRoute);
// User-facing
openapi.post("/api/redeem", RedeemCodeRoute);
// fal.ai generation
openapi.post("/api/generate/image", GenerateImageRoute);
openapi.post("/api/generate/video", GenerateVideoRoute);
openapi.get("/api/generate/history", GenerateHistoryRoute);
openapi.get("/api/generate/status/:id", GenerateStatusRoute);
openapi.get("/api/generate/:id", GenerateGetRoute);
openapi.delete("/api/generate/:id", GenerateDeleteRoute);
openapi.options("/api/{path}", OptionsRoute);

// --- Start server ---
const port = parseInt(process.env.PORT || "3001", 10);
console.log(`TAI server starting on port ${port}...`);

serve({ fetch: app.fetch, port }, (info) => {
	console.log(`TAI server running at http://localhost:${info.port}`);
});

// Graceful shutdown
process.on("SIGINT", () => {
	console.log("Shutting down...");
	sqlite.close();
	process.exit(0);
});
process.on("SIGTERM", () => {
	console.log("Shutting down...");
	sqlite.close();
	process.exit(0);
});
