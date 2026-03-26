CREATE TABLE IF NOT EXISTS user_entitlements (
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
);

CREATE INDEX IF NOT EXISTS idx_entitlements_user_updated ON user_entitlements(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_entitlements_user_status_dates ON user_entitlements(user_id, status, start_at, expires_at);
CREATE INDEX IF NOT EXISTS idx_entitlements_source_original_tx ON user_entitlements(source, external_original_transaction_id);
