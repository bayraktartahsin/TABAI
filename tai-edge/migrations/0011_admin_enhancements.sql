-- Migration 0011: Admin panel enhancements
-- Adds admin notes (support workflow) and discount codes.

-- Admin notes for support workflow
CREATE TABLE IF NOT EXISTS admin_notes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  author_id TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_admin_notes_user ON admin_notes(user_id, created_at DESC);

-- Discount codes
CREATE TABLE IF NOT EXISTS discount_codes (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE COLLATE NOCASE,
  plan_tier TEXT NOT NULL,
  duration_days INTEGER NOT NULL,
  max_uses INTEGER NOT NULL DEFAULT 1,
  current_uses INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_by TEXT,
  created_at TEXT NOT NULL,
  expires_at TEXT,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Discount code redemptions
CREATE TABLE IF NOT EXISTS discount_redemptions (
  id TEXT PRIMARY KEY,
  code_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  redeemed_at TEXT NOT NULL,
  FOREIGN KEY (code_id) REFERENCES discount_codes(id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_discount_redemptions_user ON discount_redemptions(user_id);

-- Add platform column to users for iOS/Android/Web tracking
ALTER TABLE users ADD COLUMN signup_platform TEXT DEFAULT 'web';

-- Add duration_ms to usage_events for response time tracking
ALTER TABLE usage_events ADD COLUMN duration_ms INTEGER DEFAULT 0;
