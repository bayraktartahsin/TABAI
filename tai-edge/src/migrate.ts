import Database from "better-sqlite3";
import fs from "fs";
import path from "path";
import { config } from "dotenv";

config();

const dbPath = process.env.DB_PATH || path.join(process.cwd(), "data/tai.db");
fs.mkdirSync(path.dirname(dbPath), { recursive: true });

const db = new Database(dbPath);
db.pragma("journal_mode = WAL");
db.pragma("foreign_keys = ON");

// Migration tracking table
db.exec(`CREATE TABLE IF NOT EXISTS _migrations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  applied_at TEXT DEFAULT (datetime('now'))
)`);

const migrationsDir = path.join(process.cwd(), "migrations");
const files = fs
	.readdirSync(migrationsDir)
	.filter((f) => f.endsWith(".sql"))
	.sort();

for (const file of files) {
	const applied = db
		.prepare("SELECT 1 FROM _migrations WHERE name = ?")
		.get(file);
	if (applied) {
		console.log(`skip  ${file} (already applied)`);
		continue;
	}

	const sql = fs.readFileSync(path.join(migrationsDir, file), "utf-8");
	console.log(`apply ${file}...`);

	// Split into individual statements and run each one.
	// Handle "duplicate column" and other idempotent errors gracefully,
	// since init migration may already include columns that later ALTERs add.
	const statements = sql
		.split(";")
		.map((s) => s.trim())
		.filter((s) => s.length > 0);

	for (const stmt of statements) {
		try {
			db.exec(stmt);
		} catch (err: any) {
			const msg = err?.message || "";
			if (
				msg.includes("duplicate column name") ||
				msg.includes("already exists")
			) {
				console.log(`  warn: ${msg} (skipped)`);
			} else {
				throw err;
			}
		}
	}

	db.prepare("INSERT INTO _migrations (name) VALUES (?)").run(file);
	console.log(`  ok  ${file}`);
}

console.log("All migrations applied.");
db.close();
