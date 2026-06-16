-- Migration: widen pricing grain to include vex_option_id (per-option pricing).
--
-- Before: UNIQUE (shorex_id, platform_id, platform_tour_id)
-- After:  UNIQUE (shorex_id, platform_id, platform_tour_id, vex_option_id)
--
-- The option-NULL row per (shorex, platform, listing) remains as the
-- commission/promo carrier; per-option rows (vex_option_id NOT NULL) are
-- derived from the schedule-and-pricing sheets by google_sheets_sync.
--
-- Idempotent: safe to run more than once.

BEGIN;

-- Drop the old auto-named unique constraint if it still exists.
ALTER TABLE pricing
  DROP CONSTRAINT IF EXISTS pricing_shorex_id_platform_id_platform_tour_id_key;

-- Add the new grain (named) if not already present.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'pricing_grain_key'
  ) THEN
    ALTER TABLE pricing
      ADD CONSTRAINT pricing_grain_key
      UNIQUE (shorex_id, platform_id, platform_tour_id, vex_option_id);
  END IF;
END$$;

COMMIT;
