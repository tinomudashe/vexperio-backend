-- Migration: add missing reviewer_comments column to schedule_platform_entry.
--
-- The v_pending_review view selects spe.reviewer_comments but the column was
-- never added to the table (reviewer comments were stored only in the note
-- table). This caused the view to error or return nulls silently.
--
-- Idempotent: safe to run more than once.

BEGIN;

ALTER TABLE schedule_platform_entry
    ADD COLUMN IF NOT EXISTS reviewer_comments TEXT;

COMMIT;
