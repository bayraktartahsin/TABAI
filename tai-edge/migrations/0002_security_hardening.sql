CREATE TABLE IF NOT EXISTS rate_limits (
  bucket_key TEXT PRIMARY KEY,
  scope TEXT NOT NULL,
  identifier_hash TEXT NOT NULL,
  window_start_ms INTEGER NOT NULL,
  window_seconds INTEGER NOT NULL,
  count INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS usage_events (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  chat_id TEXT,
  model_id TEXT,
  endpoint TEXT NOT NULL,
  input_message_count INTEGER NOT NULL DEFAULT 0,
  input_chars INTEGER NOT NULL DEFAULT 0,
  max_tokens_requested INTEGER,
  output_chars INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL,
  finish_reason TEXT,
  ip_hash TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE SET NULL,
  FOREIGN KEY (model_id) REFERENCES models(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_scope_window ON rate_limits(scope, window_start_ms);
CREATE INDEX IF NOT EXISTS idx_usage_events_user_created ON usage_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_events_endpoint_created ON usage_events(endpoint, created_at DESC);
