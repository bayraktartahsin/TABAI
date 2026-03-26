import type Database from "better-sqlite3";

/**
 * D1-compatible wrapper around better-sqlite3.
 *
 * Matches the subset of the D1Database interface used by lib.ts helpers:
 *   db.prepare(sql).bind(...args).first<T>()
 *   db.prepare(sql).bind(...args).all<T>()
 *   db.prepare(sql).bind(...args).run()
 */

export interface D1Compat {
	prepare(sql: string): {
		bind(...args: unknown[]): {
			first<T = unknown>(): Promise<T | null>;
			all<T = unknown>(): Promise<{ results: T[] }>;
			run(): Promise<{ success: boolean; meta: Record<string, unknown> }>;
		};
	};
	batch(stmts: Array<{ sql: string; params: unknown[] }>): Promise<unknown[]>;
	exec(sql: string): Promise<{ count: number; duration: number }>;
}

export function createD1Compat(sqlite: Database.Database): D1Compat {
	return {
		prepare(sql: string) {
			return {
				bind(...args: unknown[]) {
					return {
						async first<T = unknown>(): Promise<T | null> {
							const stmt = sqlite.prepare(sql);
							const row = stmt.get(...args) as T | undefined;
							return row ?? null;
						},
						async all<T = unknown>(): Promise<{ results: T[] }> {
							const stmt = sqlite.prepare(sql);
							const rows = stmt.all(...args) as T[];
							return { results: rows };
						},
						async run(): Promise<{
							success: boolean;
							meta: Record<string, unknown>;
						}> {
							const stmt = sqlite.prepare(sql);
							const info = stmt.run(...args);
							return {
								success: true,
								meta: {
									changes: info.changes,
									last_row_id: info.lastInsertRowid,
								},
							};
						},
					};
				},
			};
		},
		async batch(
			stmts: Array<{ sql: string; params: unknown[] }>,
		): Promise<unknown[]> {
			const transaction = sqlite.transaction(() => {
				return stmts.map(({ sql, params }) => {
					const stmt = sqlite.prepare(sql);
					return stmt.run(...params);
				});
			});
			return transaction();
		},
		async exec(sql: string): Promise<{ count: number; duration: number }> {
			sqlite.exec(sql);
			return { count: 1, duration: 0 };
		},
	};
}
