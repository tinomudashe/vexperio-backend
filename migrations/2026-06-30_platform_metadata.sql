-- Add metadata columns for dynamic platforms
ALTER TABLE platform ADD COLUMN IF NOT EXISTS short_code TEXT;
ALTER TABLE platform ADD COLUMN IF NOT EXISTS icon_url TEXT;
ALTER TABLE platform ADD COLUMN IF NOT EXISTS domain TEXT;
ALTER TABLE platform ADD COLUMN IF NOT EXISTS supplier_url_prefix TEXT;
ALTER TABLE platform ADD COLUMN IF NOT EXISTS valid_statuses JSONB;
ALTER TABLE platform ADD COLUMN IF NOT EXISTS id_placeholder TEXT;
ALTER TABLE platform ADD COLUMN IF NOT EXISTS id_hint TEXT;
ALTER TABLE platform ADD COLUMN IF NOT EXISTS color_theme TEXT;

-- Pre-populate metadata for existing platforms (optional but good for consistency)
UPDATE platform SET short_code = 'GY', domain = 'getyourguide.com', supplier_url_prefix = 'https://supplier.getyourguide.com', valid_statuses = '["ACTIVE", "INACTIVE"]'::jsonb, id_placeholder = '674024', color_theme = 'gyg' WHERE name = 'GetYourGuide';
UPDATE platform SET short_code = 'VI', domain = 'viator.com', supplier_url_prefix = 'https://supplier.viator.com', valid_statuses = '["ACTIVE", "INACTIVE"]'::jsonb, id_placeholder = 'P138', color_theme = 'via' WHERE name = 'Viator';
UPDATE platform SET short_code = 'PE', domain = 'projectexpedition.com', valid_statuses = '["ACTIVE", "INACTIVE"]'::jsonb, id_placeholder = 'PRD...', color_theme = 'pe' WHERE name IN ('PE', 'Project Expedition');
UPDATE platform SET short_code = 'VX', color_theme = 'vex' WHERE name = 'Vexperio';
