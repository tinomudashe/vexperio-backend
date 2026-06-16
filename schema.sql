-- =============================================================
-- Vexperio Tour Operations Database
-- Normalised PostgreSQL schema  — v3
-- Platforms: Vexperio (master), GetYourGuide, Viator, Project Expedition
-- Two schedule systems:
--   1. option_availability  — CMS recurring schedule per tour option
--      (weekly days + multiple start times + blocked periods)
--   2. tour_schedule        — ship-docking-driven shared tour runs
-- Change tracking via change_log + pricing_history
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- REFERENCE / LOOKUP TABLES
-- ─────────────────────────────────────────────────────────────

CREATE TABLE port (
    port_id  SERIAL PRIMARY KEY,
    name     TEXT NOT NULL UNIQUE       -- Le Havre | Le Verdon | Cherbourg
);

CREATE TABLE ship (
    ship_id  SERIAL PRIMARY KEY,
    name     TEXT NOT NULL UNIQUE
);

CREATE TABLE platform (
    platform_id         SERIAL PRIMARY KEY,
    name                TEXT NOT NULL UNIQUE,  -- Vexperio | GetYourGuide | Viator | Project Expedition
    commission_pct      NUMERIC(6,4),          -- fallback default; overrides live in platform_commission
    applies_commission  BOOLEAN NOT NULL DEFAULT TRUE  -- FALSE for Vexperio (in-house)
);

-- Logical shore-excursion families
-- (Paris Shared, POYO, D-DAY, HnD, MSM, …)
CREATE TABLE shore_excursion (
    shorex_id       SERIAL PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,
    primary_port_id INT REFERENCES port(port_id)
);

-- ─────────────────────────────────────────────────────────────
-- VEXPERIO MASTER CATALOG  (source of truth for all platforms)
-- ─────────────────────────────────────────────────────────────

CREATE TABLE tour (
    tour_id   INT PRIMARY KEY,           -- Vexperio tour ID  e.g. 1385, 1345
    shorex_id INT NOT NULL REFERENCES shore_excursion(shorex_id),
    name      TEXT NOT NULL,
    status    TEXT NOT NULL CHECK (status IN ('Published', 'Draft', 'Excluded')),
    link      TEXT
);

-- One row per bookable slot.
-- is_private lives HERE because the same tour (e.g. 1385) can have
-- both shared options (No) and private options (Yes).
CREATE TABLE tour_option (
    option_id  INT PRIMARY KEY,          -- Vexperio option ID  e.g. 4634, 1895
    tour_id    INT NOT NULL REFERENCES tour(tour_id),
    name       TEXT NOT NULL,
    is_private BOOLEAN NOT NULL DEFAULT FALSE,
    ship_id    INT REFERENCES ship(ship_id),   -- NULL → generic / combined slot
    base_price NUMERIC(10,2),
    link       TEXT
);

-- ─────────────────────────────────────────────────────────────
-- CMS OPTION AVAILABILITY SCHEDULE
-- Mirrors what the Vexperio CMS stores per tour option:
--   • weekly recurring days (Mon–Sun toggles)
--   • one or more start times per day
--   • blocked dates / date ranges
-- Private options use this schedule exclusively.
-- Shared options link here AND to tour_schedule (docking-driven).
-- ─────────────────────────────────────────────────────────────

-- One availability rule per tour option (usually one, but allows
-- multiple if the option has different rules for different periods)
CREATE TABLE option_availability (
    availability_id  SERIAL PRIMARY KEY,
    option_id        INT  NOT NULL REFERENCES tour_option(option_id),
    schedule_type    TEXT NOT NULL DEFAULT 'weekly_recurring'
                         CHECK (schedule_type IN ('weekly_recurring', 'specific_dates')),
    valid_from       DATE NOT NULL,
    valid_to         DATE,                    -- NULL = open-ended (e.g. 30.06.2038)
    -- weekly day toggles (true = available that day)
    mon              BOOLEAN NOT NULL DEFAULT FALSE,
    tue              BOOLEAN NOT NULL DEFAULT FALSE,
    wed              BOOLEAN NOT NULL DEFAULT FALSE,
    thu              BOOLEAN NOT NULL DEFAULT FALSE,
    fri              BOOLEAN NOT NULL DEFAULT FALSE,
    sat              BOOLEAN NOT NULL DEFAULT FALSE,
    sun              BOOLEAN NOT NULL DEFAULT FALSE,
    cms_status       TEXT NOT NULL DEFAULT 'Active'
                         CHECK (cms_status IN ('Active', 'Inactive', 'Draft'))
);

-- Multiple start times per availability rule
-- (e.g. 06:30, 07:00, 07:30, 08:00, 08:30 … 11:30 in the screenshot)
CREATE TABLE option_start_time (
    start_time_id   SERIAL PRIMARY KEY,
    availability_id INT  NOT NULL REFERENCES option_availability(availability_id)
                         ON DELETE CASCADE,
    start_time      TIME NOT NULL,
    UNIQUE (availability_id, start_time)
);

-- Blocked dates and date ranges (the pink chips in the screenshot)
CREATE TABLE option_blocked_period (
    blocked_id      SERIAL PRIMARY KEY,
    availability_id INT  NOT NULL REFERENCES option_availability(availability_id)
                         ON DELETE CASCADE,
    date_from       DATE NOT NULL,
    date_to         DATE NOT NULL,            -- same as date_from for single-day blocks
    reason          TEXT,
    CONSTRAINT chk_blocked_range CHECK (date_to >= date_from)
);

CREATE INDEX idx_availability_option  ON option_availability (option_id);
CREATE INDEX idx_blocked_period_dates ON option_blocked_period (availability_id, date_from, date_to);

-- ─────────────────────────────────────────────────────────────
-- PLATFORM LISTINGS  (GetYourGuide, Viator, Project Expedition)
-- ─────────────────────────────────────────────────────────────

-- One row per external product listing
CREATE TABLE platform_tour (
    platform_tour_id SERIAL PRIMARY KEY,
    platform_id      INT  NOT NULL REFERENCES platform(platform_id),
    external_id      TEXT NOT NULL,   -- GYG: 674024 | Viator: P113 | PE: PRD138963
    name             TEXT NOT NULL,
    link             TEXT,
    status           TEXT,            -- Bookable | Active | Inactive | Pending-QC …
    tour_id          INT REFERENCES tour(tour_id),   -- linked Vexperio tour
    UNIQUE (platform_id, external_id)
);

-- One row per external option → maps to a Vexperio tour_option
CREATE TABLE platform_option (
    platform_option_id SERIAL PRIMARY KEY,
    platform_tour_id   INT  NOT NULL REFERENCES platform_tour(platform_tour_id),
    external_option_id TEXT,           -- GYG numeric ID; Viator uses option name as key
    name               TEXT NOT NULL,
    vex_option_id      INT  REFERENCES tour_option(option_id),
    ship_id            INT  REFERENCES ship(ship_id),  -- convenience copy from option name
    link               TEXT            -- direct URL to this option on the platform
);

-- ─────────────────────────────────────────────────────────────
-- SHIP DOCKING SCHEDULES
-- Shared-tour availability is derived entirely from dockings.
-- Private tours can be booked independently of dockings.
-- ─────────────────────────────────────────────────────────────

CREATE TABLE ship_docking (
    docking_id SERIAL PRIMARY KEY,
    ship_id    INT  NOT NULL REFERENCES ship(ship_id),
    port_id    INT  NOT NULL REFERENCES port(port_id),
    date       DATE NOT NULL,
    dock_start TIME,
    dock_end   TIME,
    UNIQUE (ship_id, date)             -- one docking per ship per day
);

-- Each docking spawns one or more tour runs
-- (same docking: Paris Shared at 07:30, POYO at 07:30, D-DAY at 08:00 …)
CREATE TABLE tour_schedule (
    schedule_id    SERIAL PRIMARY KEY,
    docking_id     INT  NOT NULL REFERENCES ship_docking(docking_id),
    shorex_id      INT  NOT NULL REFERENCES shore_excursion(shorex_id),
    start_time     TIME,
    tour_type      TEXT NOT NULL CHECK (tour_type IN ('Shared', 'Private')),
    duration_hours INT,
    status         TEXT NOT NULL CHECK (status IN ('confirmed', 'Cancelled')),
    UNIQUE (docking_id, shorex_id, tour_type, start_time)
);

-- ─────────────────────────────────────────────────────────────
-- SCHEDULE × PLATFORM PRICE ENTRIES
-- Per scheduled run, per platform option: expected price + workflow.
-- Vexperio entries reference vex_option_id only.
-- GYG / Viator entries reference platform_option_id (which in turn
-- links back to vex_option_id).
-- ─────────────────────────────────────────────────────────────

CREATE TABLE schedule_platform_entry (
    entry_id           SERIAL PRIMARY KEY,
    schedule_id        INT NOT NULL REFERENCES tour_schedule(schedule_id),
    vex_option_id      INT REFERENCES tour_option(option_id),
    platform_option_id INT REFERENCES platform_option(platform_option_id),
    expected_price     NUMERIC(10,2),
    entry_status       TEXT,           -- Opened …
    edit_status        TEXT,           -- Changed | Error | Pending | OK | edited
    -- editorial workflow
    editor             TEXT,
    reviewer           TEXT,
    reviewed           BOOLEAN NOT NULL DEFAULT FALSE,
    review             TEXT,           -- Approved | Pending | All Good | Clarification Needed
    -- comments live in note table (entity_type='schedule_platform_entry')
    -- at least one option link preferred but not enforced — data may arrive before catalog is complete
    CONSTRAINT chk_entry_option CHECK (TRUE)
);

-- ─────────────────────────────────────────────────────────────
-- PRICING  (current price state per shore-excursion × platform)
-- One row = the live price record for a given listing.
-- History is written to pricing_history automatically.
-- ─────────────────────────────────────────────────────────────

CREATE TABLE pricing (
    pricing_id       SERIAL PRIMARY KEY,
    shorex_id        INT  NOT NULL REFERENCES shore_excursion(shorex_id),
    platform_id      INT  NOT NULL REFERENCES platform(platform_id),
    platform_tour_id INT  REFERENCES platform_tour(platform_tour_id),
    vex_option_id    INT  REFERENCES tour_option(option_id),  -- populated for Vexperio rows
    price            NUMERIC(10,2),
    commission_pct   NUMERIC(6,4),
    promo_name       TEXT,
    promo_pct        NUMERIC(6,4),
    platform_status  TEXT,            -- Published | Active | Bookable | Pending-QC …
    link             TEXT,
    -- editorial workflow state (comments/descriptions live in note table)
    change_status    TEXT,            -- Changed | Error
    editor           TEXT,
    reviewer         TEXT,
    reviewed         BOOLEAN NOT NULL DEFAULT FALSE,
    review           TEXT,            -- Approved | Pending
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Grain is per (listing × option). The option-NULL row per (shorex, platform,
    -- listing) is the commission/promo carrier synced from the flat Pricing sheet;
    -- per-option rows are derived from the schedule-and-pricing sheets.
    CONSTRAINT pricing_grain_key UNIQUE (shorex_id, platform_id, platform_tour_id, vex_option_id)
);

-- ─────────────────────────────────────────────────────────────
-- NOTES  (append-only comments attached to any entity)
-- Replaces the change_details / reviewer_comments text blobs.
-- note_type:
--   change      → why this change was made (platform rules, exceptions, calc)
--   review      → reviewer feedback / action taken
--   general     → free-form staff note (rescheduling, context, follow-up)
-- entity_type matches table name: 'pricing' | 'schedule_platform_entry' |
--   'tour_option' | 'platform_option' | 'departure' | …
-- ─────────────────────────────────────────────────────────────

CREATE TABLE note (
    note_id      SERIAL PRIMARY KEY,
    entity_type  TEXT        NOT NULL,
    entity_id    INT         NOT NULL,
    note_type    TEXT        NOT NULL DEFAULT 'general'
                     CHECK (note_type IN ('change', 'review', 'general')),
    body         TEXT        NOT NULL,
    author       TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_note_entity     ON note (entity_type, entity_id);
CREATE INDEX idx_note_type       ON note (note_type);
CREATE INDEX idx_note_created_at ON note (created_at DESC);

-- ─────────────────────────────────────────────────────────────
-- CHANGE LOG  (append-only audit trail across all entities)
-- Written by application code (or triggers) whenever a record is
-- created / updated in: tour, tour_option, platform_tour,
-- platform_option, tour_schedule, schedule_platform_entry, pricing
-- ─────────────────────────────────────────────────────────────

CREATE TABLE change_log (
    log_id            SERIAL PRIMARY KEY,
    entity_type       TEXT NOT NULL,   -- 'pricing' | 'schedule_platform_entry' | 'tour_option' | …
    entity_id         INT  NOT NULL,   -- PK of the changed row
    -- what changed
    field_name        TEXT,            -- e.g. 'price', 'platform_status', 'vex_option_id'
    old_value         TEXT,
    new_value         TEXT,
    -- who did it
    editor            TEXT,
    edit_status       TEXT,            -- Changed | Error | Pending | OK
    -- review
    reviewer          TEXT,
    reviewed          BOOLEAN NOT NULL DEFAULT FALSE,
    review            TEXT,            -- Approved | Pending | All Good | Clarification Needed
    -- descriptions and reviewer comments live in note table (entity_type='change_log')
    -- timestamps
    changed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at       TIMESTAMPTZ
);

CREATE INDEX idx_change_log_entity ON change_log (entity_type, entity_id);
CREATE INDEX idx_change_log_changed_at ON change_log (changed_at DESC);
CREATE INDEX idx_change_log_review ON change_log (review) WHERE reviewed = FALSE;

-- ─────────────────────────────────────────────────────────────
-- PRICING HISTORY  (full row snapshot before each pricing update)
-- ─────────────────────────────────────────────────────────────

CREATE TABLE pricing_history (
    history_id       SERIAL PRIMARY KEY,
    pricing_id       INT  NOT NULL,    -- references pricing(pricing_id), not FK (row may be deleted)
    shorex_id        INT  NOT NULL,
    platform_id      INT  NOT NULL,
    platform_tour_id INT,
    price            NUMERIC(10,2),
    commission_pct   NUMERIC(6,4),
    promo_name       TEXT,
    promo_pct        NUMERIC(6,4),
    platform_status  TEXT,
    change_status    TEXT,
    editor           TEXT,
    reviewer         TEXT,
    review           TEXT,
    snapshotted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- notes for this snapshot live in note table (entity_type='pricing_history')
);

-- ─────────────────────────────────────────────────────────────
-- DEPARTURES
-- A departure is one concrete bookable instance of a tour option
-- on a specific date + start time.
--
-- Source rules:
--   schedule  → generated from option_availability + option_start_time
--               (private tours, and shared tours with a CMS rule)
--   docking   → generated from ship_docking + tour_schedule
--               (shared tours driven by a ship calling at port)
--   manual    → created by staff outside of any rule
--
-- Any departure can be manually closed regardless of its source.
-- Blocked periods (option_blocked_period) prevent generation but
-- do not close already-created departures — manual_close does that.
-- ─────────────────────────────────────────────────────────────

CREATE TABLE departure (
    departure_id     SERIAL PRIMARY KEY,
    option_id        INT  NOT NULL REFERENCES tour_option(option_id),

    -- when
    departure_date   DATE NOT NULL,
    start_time       TIME NOT NULL,

    -- source that generated this departure (mutually exclusive)
    source           TEXT NOT NULL
                         CHECK (source IN ('schedule', 'docking', 'manual')),
    availability_id  INT  REFERENCES option_availability(availability_id),  -- set when source = 'schedule'
    docking_id       INT  REFERENCES ship_docking(docking_id),              -- set when source = 'docking'

    -- current state
    status           TEXT NOT NULL DEFAULT 'open'
                         CHECK (status IN ('open', 'closed', 'cancelled', 'completed')),

    -- manual close fields (populated when staff explicitly close a departure)
    manually_closed  BOOLEAN NOT NULL DEFAULT FALSE,
    closed_by        TEXT,
    closed_at        TIMESTAMPTZ,
    close_reason     TEXT,

    -- capacity (optional, can be NULL if unlimited)
    max_pax          INT,

    -- timestamps
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- one departure per option + date + time
    UNIQUE (option_id, departure_date, start_time),

    CONSTRAINT chk_departure_source CHECK (
        (source = 'schedule' AND availability_id IS NOT NULL AND docking_id IS NULL)
        OR (source = 'docking' AND docking_id IS NOT NULL AND availability_id IS NULL)
        OR (source = 'manual'  AND availability_id IS NULL AND docking_id IS NULL)
    ),
    CONSTRAINT chk_manual_close CHECK (
        manually_closed = FALSE
        OR (manually_closed = TRUE AND closed_by IS NOT NULL AND closed_at IS NOT NULL)
    )
);

CREATE INDEX idx_departure_option      ON departure (option_id);
CREATE INDEX idx_departure_date        ON departure (departure_date);
CREATE INDEX idx_departure_docking     ON departure (docking_id) WHERE docking_id IS NOT NULL;
CREATE INDEX idx_departure_open        ON departure (departure_date, status) WHERE status = 'open';
CREATE INDEX idx_departure_closed      ON departure (manually_closed) WHERE manually_closed = TRUE;

-- ─────────────────────────────────────────────────────────────
-- PLATFORM COMMISSIONS
-- Vexperio is in-house so it has no commission.
-- Other platforms (GYG, Viator, PE) have a default rate on the
-- platform table. This table stores overrides at any level:
--   platform only          → applies to all tours on that platform
--   platform + shorex      → applies to all tours in that family
--   platform + tour        → applies to one specific tour
--   platform + option      → most specific override
-- Resolution order: option > tour > shorex > platform default
-- ─────────────────────────────────────────────────────────────

CREATE TABLE platform_commission (
    commission_id   SERIAL PRIMARY KEY,
    platform_id     INT  NOT NULL REFERENCES platform(platform_id),
    -- optional scope (narrower = higher priority)
    shorex_id       INT  REFERENCES shore_excursion(shorex_id),
    tour_id         INT  REFERENCES tour(tour_id),
    option_id       INT  REFERENCES tour_option(option_id),
    -- rate
    commission_pct  NUMERIC(6,4) NOT NULL,
    -- validity window
    valid_from      DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to        DATE,                      -- NULL = indefinite
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Vexperio (platform_id=1) is in-house — enforced in application layer
    CONSTRAINT chk_commission_range CHECK (
        commission_pct > 0 AND commission_pct < 1
    ),
    CONSTRAINT chk_commission_validity CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE INDEX idx_commission_platform ON platform_commission (platform_id);
CREATE INDEX idx_commission_option   ON platform_commission (option_id) WHERE option_id IS NOT NULL;
CREATE INDEX idx_commission_tour     ON platform_commission (tour_id)   WHERE tour_id   IS NOT NULL;

-- ─────────────────────────────────────────────────────────────
-- DISCOUNTS
-- Applies across all platforms including Vexperio.
-- Scope works the same hierarchy as commissions:
--   platform + option > platform + tour > platform + shorex > platform > all platforms
-- discount_type:
--   percentage   → value is 0–1  (e.g. 0.10 = 10 % off)
--   fixed_amount → value is EUR  (e.g. 15.00 = €15 off)
-- ─────────────────────────────────────────────────────────────

CREATE TABLE discount (
    discount_id     SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    -- scope (all nullable = applies everywhere)
    platform_id     INT  REFERENCES platform(platform_id),
    shorex_id       INT  REFERENCES shore_excursion(shorex_id),
    tour_id         INT  REFERENCES tour(tour_id),
    option_id       INT  REFERENCES tour_option(option_id),
    platform_option_id INT REFERENCES platform_option(platform_option_id),
    -- value: percentage stored as 0–1  (e.g. 0.10 = 10% off)
    discount_pct    NUMERIC(6,4) NOT NULL CHECK (discount_pct > 0 AND discount_pct <= 1),
    -- validity
    valid_from      DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to        DATE,
    -- state
    status          TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'inactive', 'expired')),
    created_by      TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_discount_validity CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE INDEX idx_discount_platform ON discount (platform_id) WHERE platform_id IS NOT NULL;
CREATE INDEX idx_discount_option   ON discount (option_id)   WHERE option_id   IS NOT NULL;
CREATE INDEX idx_discount_plat_opt ON discount (platform_option_id) WHERE platform_option_id IS NOT NULL;
CREATE INDEX idx_discount_active   ON discount (valid_from, valid_to) WHERE status = 'active';

-- ─────────────────────────────────────────────────────────────
-- HELPFUL INDEXES
-- ─────────────────────────────────────────────────────────────

CREATE INDEX idx_tour_option_tour       ON tour_option (tour_id);
CREATE INDEX idx_tour_option_ship       ON tour_option (ship_id);
CREATE INDEX idx_platform_option_tour   ON platform_option (platform_tour_id);
CREATE INDEX idx_platform_option_vex    ON platform_option (vex_option_id);
CREATE INDEX idx_docking_date           ON ship_docking (date);
CREATE INDEX idx_docking_ship           ON ship_docking (ship_id);
CREATE INDEX idx_schedule_docking       ON tour_schedule (docking_id);
CREATE INDEX idx_schedule_shorex        ON tour_schedule (shorex_id);
CREATE INDEX idx_entry_schedule         ON schedule_platform_entry (schedule_id);
CREATE INDEX idx_pricing_shorex         ON pricing (shorex_id);
CREATE INDEX idx_pricing_pending_review ON pricing (review) WHERE reviewed = FALSE;

-- ─────────────────────────────────────────────────────────────
-- SEED DATA
-- ─────────────────────────────────────────────────────────────

INSERT INTO port (name) VALUES
    ('Le Havre'),
    ('Le Verdon'),
    ('Cherbourg');

INSERT INTO platform (name, commission_pct, applies_commission) VALUES
    ('Vexperio',             NULL,  FALSE),   -- in-house, no commission
    ('GetYourGuide',         0.371, TRUE),
    ('Viator',               0.246, TRUE),
    ('Project Expedition',   0.10,  TRUE);

INSERT INTO shore_excursion (name, primary_port_id) VALUES
    ('Paris Shared',
        (SELECT port_id FROM port WHERE name = 'Le Havre')),
    ('POYO',
        (SELECT port_id FROM port WHERE name = 'Le Havre')),
    ('D-DAY',
        (SELECT port_id FROM port WHERE name = 'Le Havre')),
    ('D-day from Cherbourg',
        (SELECT port_id FROM port WHERE name = 'Cherbourg')),
    ('HnD',
        (SELECT port_id FROM port WHERE name = 'Le Havre')),
    ('MSM',
        (SELECT port_id FROM port WHERE name = 'Le Havre')),
    ('Le Verdon - Bordeaux - shared tour',
        (SELECT port_id FROM port WHERE name = 'Le Verdon')),
    ('Bordoyo - transferon your own',
        (SELECT port_id FROM port WHERE name = 'Le Verdon')),
    ('Rouen shared',
        (SELECT port_id FROM port WHERE name = 'Le Havre'));

-- ─────────────────────────────────────────────────────────────
-- VIEWS
-- ─────────────────────────────────────────────────────────────

-- Effective commission per platform option
-- Uses the most specific override available, falls back to platform default
CREATE VIEW v_effective_commission AS
SELECT
    po.platform_option_id,
    pt.platform_id,
    pl.name                                 AS platform,
    to2.option_id,
    to2.name                                AS option_name,
    t.tour_id,
    sx.name                                 AS shore_excursion,
    to2.base_price,
    COALESCE(
        -- most specific: option-level override
        (SELECT commission_pct FROM platform_commission pc
         WHERE pc.platform_id = pt.platform_id
           AND pc.option_id   = to2.option_id
           AND CURRENT_DATE BETWEEN pc.valid_from AND COALESCE(pc.valid_to, '9999-12-31')
         ORDER BY pc.valid_from DESC LIMIT 1),
        -- tour-level override
        (SELECT commission_pct FROM platform_commission pc
         WHERE pc.platform_id = pt.platform_id
           AND pc.tour_id     = t.tour_id
           AND pc.option_id IS NULL
           AND CURRENT_DATE BETWEEN pc.valid_from AND COALESCE(pc.valid_to, '9999-12-31')
         ORDER BY pc.valid_from DESC LIMIT 1),
        -- shore excursion level override
        (SELECT commission_pct FROM platform_commission pc
         WHERE pc.platform_id = pt.platform_id
           AND pc.shorex_id   = sx.shorex_id
           AND pc.tour_id IS NULL AND pc.option_id IS NULL
           AND CURRENT_DATE BETWEEN pc.valid_from AND COALESCE(pc.valid_to, '9999-12-31')
         ORDER BY pc.valid_from DESC LIMIT 1),
        -- platform default
        pl.commission_pct
    )                                       AS effective_commission_pct,
    ROUND(to2.base_price *
        (1 - COALESCE(
            (SELECT commission_pct FROM platform_commission pc
             WHERE pc.platform_id = pt.platform_id AND pc.option_id = to2.option_id
               AND CURRENT_DATE BETWEEN pc.valid_from AND COALESCE(pc.valid_to, '9999-12-31')
             ORDER BY pc.valid_from DESC LIMIT 1),
            pl.commission_pct
        )), 2)                              AS net_revenue
FROM platform_option   po
JOIN platform_tour  pt  ON pt.platform_tour_id = po.platform_tour_id
JOIN platform       pl  ON pl.platform_id      = pt.platform_id
JOIN tour_option   to2  ON to2.option_id       = po.vex_option_id
JOIN tour           t   ON t.tour_id           = to2.tour_id
JOIN shore_excursion sx ON sx.shorex_id        = t.shorex_id
WHERE pl.name <> 'Vexperio';

-- Active discounts with their scope details
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

-- Departure calendar — open and closed departures with context
CREATE VIEW v_departure_calendar AS
SELECT
    d.departure_id,
    d.departure_date,
    d.start_time,
    sh.name                             AS ship,           -- populated for docking-sourced
    p.name                              AS port,
    sx.name                             AS shore_excursion,
    t.tour_id,
    t.name                              AS tour_name,
    to2.option_id,
    to2.name                            AS option_name,
    to2.is_private,
    d.source,
    d.status,
    d.manually_closed,
    d.closed_by,
    d.closed_at,
    d.close_reason,
    d.max_pax
FROM departure d
JOIN tour_option  to2 ON to2.option_id  = d.option_id
JOIN tour          t  ON t.tour_id      = to2.tour_id
JOIN shore_excursion sx ON sx.shorex_id = t.shorex_id
LEFT JOIN ship_docking  sd  ON sd.docking_id = d.docking_id
LEFT JOIN ship          sh  ON sh.ship_id    = sd.ship_id
LEFT JOIN port          p   ON p.port_id     = sd.port_id
ORDER BY d.departure_date, d.start_time;

-- Manually closed departures log
CREATE VIEW v_manual_closures AS
SELECT
    d.departure_id,
    d.departure_date,
    d.start_time,
    sx.name                             AS shore_excursion,
    to2.name                            AS option_name,
    to2.is_private,
    sh.name                             AS ship,
    d.close_reason,
    d.closed_by,
    d.closed_at
FROM departure d
JOIN tour_option  to2 ON to2.option_id  = d.option_id
JOIN tour          t  ON t.tour_id      = to2.tour_id
JOIN shore_excursion sx ON sx.shorex_id = t.shorex_id
LEFT JOIN ship_docking sd ON sd.docking_id = d.docking_id
LEFT JOIN ship         sh ON sh.ship_id    = sd.ship_id
WHERE d.manually_closed = TRUE
ORDER BY d.closed_at DESC;

-- Option availability summary: start times + blocked periods per option
CREATE VIEW v_option_availability AS
SELECT
    to2.option_id,
    to2.name                            AS option_name,
    t.tour_id,
    t.name                              AS tour_name,
    sx.name                             AS shore_excursion,
    to2.is_private,
    oa.availability_id,
    oa.valid_from,
    oa.valid_to,
    oa.cms_status,
    -- day toggles as a readable list
    TRIM(BOTH ',' FROM
        CONCAT_WS(',',
            CASE WHEN oa.mon THEN 'Mon' END,
            CASE WHEN oa.tue THEN 'Tue' END,
            CASE WHEN oa.wed THEN 'Wed' END,
            CASE WHEN oa.thu THEN 'Thu' END,
            CASE WHEN oa.fri THEN 'Fri' END,
            CASE WHEN oa.sat THEN 'Sat' END,
            CASE WHEN oa.sun THEN 'Sun' END
        )
    )                                   AS active_days,
    -- aggregated start times
    (SELECT STRING_AGG(ost.start_time::TEXT, ', ' ORDER BY ost.start_time)
     FROM option_start_time ost
     WHERE ost.availability_id = oa.availability_id
    )                                   AS start_times,
    -- count of blocked periods
    (SELECT COUNT(*)
     FROM option_blocked_period obp
     WHERE obp.availability_id = oa.availability_id
    )                                   AS blocked_periods_count
FROM option_availability  oa
JOIN tour_option  to2 ON to2.option_id = oa.option_id
JOIN tour          t  ON t.tour_id     = to2.tour_id
JOIN shore_excursion sx ON sx.shorex_id = t.shorex_id
ORDER BY sx.name, to2.option_id;

-- Full schedule calendar with platform price and review status
CREATE VIEW v_schedule_full AS
SELECT
    sd.date,
    sh.name                             AS ship,
    p.name                              AS port,
    sd.dock_start,
    sd.dock_end,
    sx.name                             AS shore_excursion,
    ts.start_time,
    ts.tour_type,
    ts.duration_hours,
    ts.status                           AS schedule_status,
    COALESCE(pl.name, 'Vexperio')       AS platform,
    spe.expected_price,
    spe.edit_status,
    spe.editor,
    spe.reviewer,
    spe.reviewed,
    spe.review
FROM tour_schedule ts
JOIN ship_docking    sd  ON sd.docking_id  = ts.docking_id
JOIN ship            sh  ON sh.ship_id     = sd.ship_id
JOIN port            p   ON p.port_id      = sd.port_id
JOIN shore_excursion sx  ON sx.shorex_id   = ts.shorex_id
LEFT JOIN schedule_platform_entry spe ON spe.schedule_id = ts.schedule_id
LEFT JOIN platform_option po  ON po.platform_option_id = spe.platform_option_id
LEFT JOIN platform_tour   pt  ON pt.platform_tour_id   = po.platform_tour_id
LEFT JOIN platform        pl  ON pl.platform_id        = pt.platform_id
ORDER BY sd.date, sh.name, ts.start_time;

-- Cross-platform pricing snapshot per shore excursion
CREATE VIEW v_pricing_overview AS
SELECT
    sx.name                             AS shore_excursion,
    pl.name                             AS platform,
    COALESCE(pt.external_id, '')        AS platform_id,
    pt.name                             AS platform_tour_name,
    pr.price,
    pr.commission_pct,
    ROUND(pr.price * (1 - pr.commission_pct), 2) AS net_revenue,
    pr.platform_status,
    pr.change_status,
    pr.review,
    pr.reviewed,
    pr.editor,
    pr.reviewer
FROM pricing pr
JOIN shore_excursion sx  ON sx.shorex_id   = pr.shorex_id
JOIN platform        pl  ON pl.platform_id = pr.platform_id
LEFT JOIN platform_tour  pt  ON pt.platform_tour_id = pr.platform_tour_id
ORDER BY sx.name, pl.name;

-- Pending review queue (items waiting for reviewer action)
CREATE VIEW v_pending_review AS
SELECT
    'pricing'                   AS source,
    pr.pricing_id               AS entity_id,
    sx.name                     AS shore_excursion,
    pl.name                     AS platform,
    pr.change_details,
    pr.change_status,
    pr.editor,
    pr.reviewer,
    pr.reviewer_comments,
    pr.updated_at               AS changed_at
FROM pricing pr
JOIN shore_excursion sx ON sx.shorex_id   = pr.shorex_id
JOIN platform        pl ON pl.platform_id = pr.platform_id
WHERE pr.reviewed = FALSE AND pr.change_status IS NOT NULL

UNION ALL

SELECT
    'schedule'                  AS source,
    spe.entry_id                AS entity_id,
    sx.name                     AS shore_excursion,
    COALESCE(pl.name,'Vexperio') AS platform,
    NULL                        AS change_details,
    spe.edit_status             AS change_status,
    spe.editor,
    spe.reviewer,
    spe.reviewer_comments,
    NULL                        AS changed_at
FROM schedule_platform_entry spe
JOIN tour_schedule   ts  ON ts.schedule_id  = spe.schedule_id
JOIN shore_excursion sx  ON sx.shorex_id    = ts.shorex_id
LEFT JOIN platform_option po  ON po.platform_option_id = spe.platform_option_id
LEFT JOIN platform_tour   pt  ON pt.platform_tour_id   = po.platform_tour_id
LEFT JOIN platform        pl  ON pl.platform_id        = pt.platform_id
WHERE spe.reviewed = FALSE AND spe.edit_status IS NOT NULL;

-- GUIDELINES
CREATE TABLE guideline (
    guideline_id   SERIAL PRIMARY KEY,
    type           TEXT NOT NULL,  -- 'general', 'platform', 'port_excursion'
    entity_name    TEXT,           -- e.g., 'Viator', 'MSM from Cherbourg', 'General'
    platform_id    INT REFERENCES platform(platform_id),
    port_id        INT REFERENCES port(port_id),
    updated_by     TEXT,
    created_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
    updated_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

CREATE TABLE guideline_attribute (
    attribute_id   SERIAL PRIMARY KEY,
    guideline_id   INT NOT NULL REFERENCES guideline(guideline_id) ON DELETE CASCADE,
    key_name       TEXT NOT NULL,
    value_text     TEXT NOT NULL,
    order_index    INT NOT NULL DEFAULT 0,
    created_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
    updated_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);
