-- Register TABAI composite model as a virtual model
INSERT OR IGNORE INTO models (id, provider_model_id, name, vendor, logo, description, capabilities_json, context_length, pricing_tier, is_enabled, verified, created_at, updated_at)
VALUES (
  'tabai',
  'tabai',
  'TABAI',
  'tabai',
  NULL,
  'Smart AI — automatically picks the best model for your question',
  '["streaming"]',
  32768,
  'free',
  1,
  1,
  datetime('now'),
  datetime('now')
);
