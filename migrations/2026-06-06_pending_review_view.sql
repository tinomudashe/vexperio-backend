-- Migration: rebuild v_pending_review to source change_details and
-- reviewer_comments from the note table instead of deprecated text columns
-- on the pricing table (which are no longer written by the API).
--
-- Also incorporates the now-added reviewer_comments column on
-- schedule_platform_entry (see 2026-06-06_spe_reviewer_comments.sql).
--
-- Idempotent: DROP + CREATE REPLACE is safe to run more than once.

BEGIN;

DROP VIEW IF EXISTS v_pending_review;

CREATE VIEW v_pending_review AS

-- ── Pricing changes awaiting review ──────────────────────────────────────────
SELECT
    'pricing'                   AS source,
    pr.pricing_id               AS entity_id,
    sx.name                     AS shore_excursion,
    pl.name                     AS platform,
    -- most-recent change note body
    (SELECT n.body
     FROM note n
     WHERE n.entity_type = 'pricing'
       AND n.entity_id   = pr.pricing_id
       AND n.note_type   = 'change'
     ORDER BY n.created_at DESC
     LIMIT 1
    )                           AS change_details,
    pr.change_status,
    pr.editor,
    pr.reviewer,
    -- most-recent review note body
    (SELECT n.body
     FROM note n
     WHERE n.entity_type = 'pricing'
       AND n.entity_id   = pr.pricing_id
       AND n.note_type   = 'review'
     ORDER BY n.created_at DESC
     LIMIT 1
    )                           AS reviewer_comments,
    pr.updated_at               AS changed_at
FROM pricing pr
JOIN shore_excursion sx ON sx.shorex_id   = pr.shorex_id
JOIN platform        pl ON pl.platform_id = pr.platform_id
WHERE pr.reviewed = FALSE
  AND pr.change_status IS NOT NULL

UNION ALL

-- ── Schedule entries awaiting review ─────────────────────────────────────────
SELECT
    'schedule'                       AS source,
    spe.entry_id                     AS entity_id,
    sx.name                          AS shore_excursion,
    COALESCE(pl.name, 'Vexperio')    AS platform,
    NULL                             AS change_details,
    spe.edit_status                  AS change_status,
    spe.editor,
    spe.reviewer,
    spe.reviewer_comments,
    NULL                             AS changed_at
FROM schedule_platform_entry spe
JOIN tour_schedule   ts  ON ts.schedule_id  = spe.schedule_id
JOIN shore_excursion sx  ON sx.shorex_id    = ts.shorex_id
LEFT JOIN platform_option po  ON po.platform_option_id = spe.platform_option_id
LEFT JOIN platform_tour   pt  ON pt.platform_tour_id   = po.platform_tour_id
LEFT JOIN platform        pl  ON pl.platform_id        = pt.platform_id
WHERE spe.reviewed = FALSE
  AND spe.edit_status IS NOT NULL;

COMMIT;
