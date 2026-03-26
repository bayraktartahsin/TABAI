import { Bool, DateTime, Num, OpenAPIRoute, Str } from "chanfana";
import type { Context } from "hono";
import { z } from "zod";

export type AppContext = Context<{ Bindings: Env }>;

export const UserRole = z.enum(["ADMIN", "USER"]);
export const UserStatus = z.enum(["ENABLED", "FROZEN"]);

export const EntitlementSchema = z.object({
	id: Str(),
	userId: Str(),
	planTier: Str(),
	source: Str(),
	status: Str(),
	startAt: DateTime(),
	expiresAt: z.union([Str(), z.null()]),
	autoRenew: Bool(),
	externalProductId: z.union([Str(), z.null()]),
	externalOriginalTransactionId: z.union([Str(), z.null()]),
	lastValidatedAt: z.union([Str(), z.null()]),
	updatedAt: DateTime(),
});

export const UserSchema = z.object({
	id: Str(),
	email: Str(),
	username: Str(),
	displayName: Str({ required: false }),
	role: UserRole,
	status: UserStatus,
	planTier: Str(),
	emailVerified: Bool(),
	verificationRequired: Bool(),
	entitlement: EntitlementSchema.nullable({ required: false }),
	lastActiveAt: z.union([Str(), z.null()]).optional(),
	createdAt: z.union([Str(), z.null()]).optional(),
});

export const SettingsSchema = z.object({
	theme: Str(),
	language: Str(),
	notificationsEnabled: Bool(),
	voiceSessionEnabled: Bool({ required: false }),
});

export const ProviderSchema = z.object({
	id: Str(),
	name: Str(),
	slug: Str(),
	type: Str(),
	endpointUrl: Str(),
	enabled: Bool(),
});

export const ModelSchema = z.object({
	id: Str(),
	providerId: Str(),
	slug: Str(),
	providerModelId: Str(),
	displayName: Str(),
	logoUrl: Str({ required: false }),
	description: Str({ required: false }),
	enabled: Bool(),
	supportsStreaming: Bool(),
	supportsTextChat: Bool({ required: false }),
	supportsVision: Bool(),
	supportsReasoning: Bool({ required: false }),
	supportsImageGeneration: Bool({ required: false }),
	vendor: Str({ required: false }),
	capabilities: z.array(Str()).default([]),
	verified: Bool(),
	verificationStatus: Str(),
	contextLength: Num({ required: false }),
	pricingTier: Str({ required: false }),
	category: Str({ required: false }),
	requiredPlanTier: Str({ required: false }),
	canAccess: Bool({ required: false }),
	lockReason: Str({ required: false }),
	provider: ProviderSchema,
});

export const FolderSchema = z.object({
	id: Str(),
	name: Str(),
	color: Str({ required: false }),
	createdAt: DateTime(),
	updatedAt: DateTime(),
});

export const MessageSchema = z.object({
	id: Str(),
	chatId: Str(),
	role: Str(),
	content: Str(),
	sequence: Num(),
	isDeleted: Bool(),
	createdAt: DateTime(),
	updatedAt: DateTime(),
});

export const ChatSchema = z.object({
	id: Str(),
	userId: Str(),
	folderId: Str({ required: false }),
	title: Str(),
	modelId: Str({ required: false }),
	isPinned: Bool(),
	isDeleted: Bool(),
	createdAt: DateTime(),
	updatedAt: DateTime(),
	folder: FolderSchema.nullable(),
	model: ModelSchema.nullable(),
	messages: z.array(MessageSchema),
});

export const BootstrapSchema = z.object({
	user: UserSchema,
	models: z.array(ModelSchema),
	chats: z.array(ChatSchema),
	settings: SettingsSchema,
});

export type AppRoute = OpenAPIRoute;
