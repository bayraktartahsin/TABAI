CREATE TABLE IF NOT EXISTS usage_ledger (
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
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (model_id) REFERENCES models(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_usage_ledger_user_created ON usage_ledger(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_ledger_status_created ON usage_ledger(status, created_at DESC);

CREATE TABLE IF NOT EXISTS active_streams (
  lease_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_active_streams_user_expires ON active_streams(user_id, expires_at);
