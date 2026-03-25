-- M8: Cost safety hard-limit infrastructure
-- Adds safety-event auditing and sliding-window request event storage.

CREATE TABLE IF NOT EXISTS rate_limit_events (
  id TEXT PRIMARY KEY,
  scope TEXT NOT NULL,
  identifier_hash TEXT NOT NULL,
  event_ms INTEGER NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_events_scope_hash_ms
  ON rate_limit_events(scope, identifier_hash, event_ms);

CREATE TABLE IF NOT EXISTS safety_events (
  id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  user_id TEXT,
  ip_hash TEXT,
  request_id TEXT,
  model_id TEXT,
  plan_tier TEXT,
  code TEXT NOT NULL,
  message TEXT NOT NULL,
  details_json TEXT,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_safety_events_type_created
  ON safety_events(event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_safety_events_user_created
  ON safety_events(user_id, created_at DESC);
