DROP VIEW IF EXISTS v_active_discounts;
ALTER TABLE discount DROP COLUMN IF EXISTS promo_code;
ALTER TABLE discount ADD COLUMN IF NOT EXISTS platform_option_id INT REFERENCES platform_option(platform_option_id);
CREATE INDEX IF NOT EXISTS idx_discount_plat_opt ON discount (platform_option_id) WHERE platform_option_id IS NOT NULL;
CREATE VIEW v_active_discounts AS
SELECT
    d.discount_id,
    d.name,
    COALESCE(pl.name, 'All platforms')      AS platform,
    COALESCE(sx.name, 'All excursions')     AS shore_excursion,
    COALESCE(t.name,  'All tours')          AS tour,
    COALESCE(to2.name,'All options')        AS option,
    ROUND(d.discount_pct * 100, 2)::TEXT || '%' AS discount_display,
    d.valid_from,
    d.valid_to
FROM discount d
LEFT JOIN platform       pl  ON pl.platform_id  = d.platform_id
LEFT JOIN shore_excursion sx ON sx.shorex_id    = d.shorex_id
LEFT JOIN tour            t  ON t.tour_id       = d.tour_id
LEFT JOIN tour_option    to2 ON to2.option_id   = d.option_id
WHERE d.status = 'active'
  AND CURRENT_DATE BETWEEN d.valid_from AND COALESCE(d.valid_to, '9999-12-31')
ORDER BY d.valid_from;
