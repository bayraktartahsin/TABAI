ALTER TABLE users ADD COLUMN plan_tier TEXT NOT NULL DEFAULT 'free';

UPDATE users
SET plan_tier = CASE
  WHEN role = 'ADMIN' THEN 'power'
  ELSE 'free'
END
WHERE plan_tier IS NULL OR plan_tier = '';
