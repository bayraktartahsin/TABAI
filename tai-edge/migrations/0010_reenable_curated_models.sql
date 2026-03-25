-- Migration 0010: Clean model display names
-- Model curation is now enforced in code via CURATED_PROVIDER_MODEL_IDS set
-- in getAccessibleModels(). The is_enabled flag is no longer used for curation.
-- This migration just cleans up "(free)" labels from display names.

UPDATE models SET name = REPLACE(name, ' (free)', '') WHERE name LIKE '% (free)%';
UPDATE models SET name = REPLACE(name, '(free)', '') WHERE name LIKE '%(free)%';
UPDATE models SET name = REPLACE(name, ' :free', '') WHERE name LIKE '% :free%';
UPDATE models SET name = RTRIM(name) WHERE name != RTRIM(name);
