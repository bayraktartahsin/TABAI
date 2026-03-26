/**
 * One-time user seeding script for TABAI backend.
 * Usage: npm run seed-users
 */
import "dotenv/config";
import * as Database from "better-sqlite3";
import * as crypto from "node:crypto";

const DB_PATH = process.env.DB_PATH || "./data/tai.db";

function base64UrlEncode(bytes: Uint8Array): string {
	let binary = "";
	for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]!);
	return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function hashPassword(password: string): Promise<string> {
	const salt = crypto.getRandomValues(new Uint8Array(16));
	const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(password), "PBKDF2", false, ["deriveBits"]);
	const bits = await crypto.subtle.deriveBits(
		{ name: "PBKDF2", hash: "SHA-256", salt, iterations: 100000 },
		key,
		256,
	);
	return `pbkdf2$100000$${base64UrlEncode(salt)}$${base64UrlEncode(new Uint8Array(bits))}`;
}

function randomId(): string {
	return crypto.randomUUID();
}

function nowIso(): string {
	return new Date().toISOString();
}

interface SeedUser {
	email: string;
	username: string;
	display_name: string;
	role: string;
	plan_tier: string;
	status: string;
	password: string;
}

const SEED_USERS: SeedUser[] = [
	{
		email: "admin@gravitilabs.com",
		username: "admin",
		display_name: "Volkan",
		role: "ADMIN",
		plan_tier: "power",
		status: "ENABLED",
		password: "TabaAdmin2026!",
	},
	{
		email: "power@gravitilabs.com",
		username: "poweruser",
		display_name: "Power User",
		role: "USER",
		plan_tier: "power",
		status: "ENABLED",
		password: "TabaPower2026!",
	},
	{
		email: "review@gravitilabs.com",
		username: "reviewer",
		display_name: "Reviewer",
		role: "USER",
		plan_tier: "pro",
		status: "ENABLED",
		password: "Taba26Review!",
	},
];

async function main() {
	console.log(`Opening database: ${DB_PATH}`);
	const db = new Database(DB_PATH);
	db.pragma("journal_mode = WAL");

	const now = nowIso();

	const findUser = db.prepare("SELECT id FROM users WHERE lower(email) = lower(?)");
	const insertUser = db.prepare(
		"INSERT INTO users (id, email, username, display_name, password_hash, role, status, plan_tier, email_verified_at, session_version, last_active_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NULL, ?, ?)",
	);
	const updateUser = db.prepare(
		"UPDATE users SET password_hash = ?, role = ?, plan_tier = ?, status = ?, email_verified_at = ?, updated_at = ? WHERE id = ?",
	);
	const insertSettings = db.prepare(
		"INSERT INTO user_settings (user_id, updated_at) VALUES (?, ?) ON CONFLICT DO NOTHING",
	);

	for (const user of SEED_USERS) {
		const passwordHash = await hashPassword(user.password);
		const existing = findUser.get(user.email) as { id: string } | undefined;

		if (existing) {
			updateUser.run(passwordHash, user.role, user.plan_tier, user.status, now, now, existing.id);
			insertSettings.run(existing.id, now);
			console.log(`Updated: ${user.email} (${existing.id})`);
		} else {
			const id = randomId();
			insertUser.run(id, user.email, user.username, user.display_name, passwordHash, user.role, user.status, user.plan_tier, now, now, now);
			insertSettings.run(id, now);
			console.log(`Created: ${user.email} (${id})`);
		}
	}

	db.close();
	console.log("Seed complete.");
}

main().catch((err) => {
	console.error("Seed failed:", err);
	process.exit(1);
});
