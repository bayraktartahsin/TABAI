-- Add 'reserving' status to generations table to support atomic budget reservation.
-- SQLite requires table recreation to modify CHECK constraints.

CREATE TABLE generations_new (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  chat_id TEXT,
  fal_request_id TEXT NOT NULL,
  provider TEXT NOT NULL DEFAULT 'fal',
  model_id TEXT NOT NULL,
  model_display_name TEXT,
  generation_type TEXT NOT NULL CHECK(generation_type IN ('image','video','image_to_video')),
  status TEXT NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','reserving','processing','completed','failed','cancelled')),
  prompt TEXT NOT NULL,
  negative_prompt TEXT,
  parameters TEXT,
  result_url TEXT,
  result_metadata TEXT,
  estimated_cost_units INTEGER DEFAULT 0,
  actual_cost_units INTEGER,
  error_message TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  completed_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (chat_id) REFERENCES chats(id)
);

INSERT INTO generations_new SELECT * FROM generations;

DROP TABLE generations;

ALTER TABLE generations_new RENAME TO generations;

CREATE INDEX idx_generations_user ON generations(user_id, created_at);
CREATE INDEX idx_generations_status ON generations(status);
CREATE INDEX idx_generations_fal ON generations(fal_request_id);
