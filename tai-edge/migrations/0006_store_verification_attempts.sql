CREATE TABLE IF NOT EXISTS store_verification_attempts (
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
);

CREATE INDEX IF NOT EXISTS idx_store_verify_user_created ON store_verification_attempts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_store_verify_provider_created ON store_verification_attempts(provider, created_at DESC);
