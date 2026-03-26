ALTER TABLE users ADD COLUMN email_verified_at TEXT;
ALTER TABLE users ADD COLUMN session_version INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN last_active_at TEXT;

UPDATE users
SET email_verified_at = COALESCE(email_verified_at, created_at)
WHERE email_verified_at IS NULL;

CREATE TABLE IF NOT EXISTS auth_tokens (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  user_id TEXT,
  email TEXT,
  token_hash TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  used_at TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_auth_tokens_type_email_created ON auth_tokens(type, email, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_auth_tokens_type_user_created ON auth_tokens(type, user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_tokens_type_hash ON auth_tokens(type, token_hash);
