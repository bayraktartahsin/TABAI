-- Migration 0009: Model Curation
-- Disable all models first, then enable only the curated set.
-- This ensures only quality, well-known models are shown to users.
-- The backend auto-categorizes models by name pattern into tiers.

-- Step 1: Disable all models
UPDATE models SET is_enabled = 0;

-- Step 2: Enable curated FREE tier models (available to all users)
UPDATE models SET is_enabled = 1 WHERE provider_model_id IN (
  'meta-llama/llama-3.1-8b-instruct:free',
  'meta-llama/llama-3.2-3b-instruct:free',
  'google/gemma-2-9b-it:free',
  'qwen/qwen-2.5-7b-instruct:free',
  'mistralai/mistral-7b-instruct:free',
  'microsoft/phi-3-mini-128k-instruct:free',
  'nousresearch/hermes-3-llama-3.1-405b:free',
  'google/gemini-2.0-flash-exp:free'
);

-- Step 3: Enable curated STARTER tier models (fast & everyday + vision)
UPDATE models SET is_enabled = 1 WHERE provider_model_id IN (
  'openai/gpt-4o-mini',
  'openai/gpt-4o-mini-2024-07-18',
  'anthropic/claude-3.5-haiku',
  'anthropic/claude-3-haiku',
  'google/gemini-2.0-flash-001',
  'google/gemini-flash-1.5',
  'meta-llama/llama-3.1-70b-instruct',
  'meta-llama/llama-3.3-70b-instruct',
  'mistralai/mistral-small-latest',
  'mistralai/mistral-small',
  'qwen/qwen-2.5-72b-instruct',
  'deepseek/deepseek-chat',
  'deepseek/deepseek-chat-v3-0324',
  'google/gemini-2.0-flash-001:vision',
  'meta-llama/llama-3.2-11b-vision-instruct'
);

-- Step 4: Enable curated PRO tier models (premium reasoning + creative)
UPDATE models SET is_enabled = 1 WHERE provider_model_id IN (
  'openai/gpt-4o',
  'openai/gpt-4o-2024-11-20',
  'anthropic/claude-3.5-sonnet',
  'anthropic/claude-3.5-sonnet-20241022',
  'anthropic/claude-sonnet-4',
  'google/gemini-1.5-pro',
  'google/gemini-2.5-pro-preview-03-25',
  'deepseek/deepseek-r1',
  'meta-llama/llama-3.1-405b-instruct',
  'mistralai/mistral-large-latest',
  'mistralai/mistral-large',
  'qwen/qwq-32b',
  'openai/o1-mini',
  'openai/o3-mini',
  'x-ai/grok-2',
  'perplexity/sonar-pro'
);

-- Step 5: Enable curated POWER tier models (everything unlocked)
UPDATE models SET is_enabled = 1 WHERE provider_model_id IN (
  'anthropic/claude-3-opus',
  'anthropic/claude-opus-4',
  'openai/gpt-4-turbo',
  'openai/o1',
  'openai/o1-preview',
  'openai/o3',
  'openai/o3-pro',
  'google/gemini-1.5-pro-latest',
  'x-ai/grok-3',
  'x-ai/grok-3-beta'
);

-- Step 6: Clean up model display names — strip any "(free)" or ":free" suffixes
-- that may have been stored in the name column from OpenRouter sync
UPDATE models SET name = REPLACE(name, ' (free)', '') WHERE name LIKE '% (free)%';
UPDATE models SET name = REPLACE(name, '(free)', '') WHERE name LIKE '%(free)%';
UPDATE models SET name = REPLACE(name, ' :free', '') WHERE name LIKE '% :free%';
UPDATE models SET name = RTRIM(name) WHERE name != RTRIM(name);
