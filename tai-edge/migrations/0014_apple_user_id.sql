-- Add apple_user_id column for Apple/Google SSO lookup by provider subject ID
ALTER TABLE users ADD COLUMN apple_user_id TEXT;

-- Index for fast lookup by apple_user_id (used in Apple Sign-In and Google Sign-In)
CREATE INDEX IF NOT EXISTS idx_users_apple_user_id ON users(apple_user_id);
