/**
 * Minimal type stubs for Cloudflare Workers APIs used in the codebase.
 * In production on Node.js, these are satisfied by the D1Compat wrapper.
 */

interface D1PreparedStatement {
	bind(...values: unknown[]): D1PreparedStatement;
	first<T = unknown>(colName?: string): Promise<T | null>;
	all<T = unknown>(): Promise<{ results: T[]; success: boolean; meta: Record<string, unknown> }>;
	run(): Promise<{ success: boolean; meta: Record<string, unknown> }>;
}

interface D1Database {
	prepare(query: string): D1PreparedStatement;
	batch<T = unknown>(statements: D1PreparedStatement[]): Promise<T[]>;
	exec(query: string): Promise<{ count: number; duration: number }>;
}

interface ExecutionContext {
	waitUntil(promise: Promise<unknown>): void;
	passThroughOnException(): void;
}

interface Env {
	DB: D1Database;
	OPENROUTER_API_KEY: string;
	FAL_AI_API_KEY: string;
	TAI_SESSION_SECRET: string;
	TAI_ENCRYPTION_KEY: string;
	TAI_REVIEWER_PASSWORD?: string;
	ASSETS?: { fetch(request: Request): Promise<Response> };
}
