# Vexperio — Codebase Context & Issue Decision Log
_Generated: 2026-06-06_

---

## System Overview

Three-layer stack: **Google Sheets → PostgreSQL (Cloud SQL, europe-west1) → Excel Add-in (Office.js)**

| Layer | Tech | Deploy |
|-------|------|--------|
| DB | PostgreSQL 15, Cloud SQL | Cloud SQL `vexperio-db` |
| API | Python FastAPI + SQLAlchemy | Cloud Run `vexperio-api` (europe-west1) |
| Add-in | React + Vite + Office.js | Cloud Run `vexperio-addin` (europe-west1) |
| Sync | `google_sheets_sync.py` | Triggered via `POST /sync/pull` |

API URL (production): `https://vexperio-api-752030257772.europe-west1.run.app`  
Add-in URL: served by Cloud Run `vexperio-addin`  
Spreadsheet ID: `16y5RQ5rbvBTbgRmvafeMWUYuRJBMNmPnyIy_NarnbaQ`

---

## Key Design Patterns

### "Mirror" writes (Excel add-in)
Excel is the source of truth for display. Every user write goes:
1. `runWithChangeComment()` — forces a typed comment before any save
2. The write function calls `mirrorToApiResult()` which wraps `apiPatch/apiPost`
3. On failure → queued in `_syncIssues` (shown in the UI as "API sync issues")
4. On success → `recordChangeAudit()` writes a `Note` to the backend

### Pricing grain (DB)
`pricing` UNIQUE key: `(shorex_id, platform_id, platform_tour_id, vex_option_id)`  
- `vex_option_id = NULL` → "carrier" row (holds commission % and promo for a listing)  
- `vex_option_id = N` → per-option derived row (price from schedule entries, commission/promo copied from carrier)

### Sync order (google_sheets_sync.py run_sync)
1. France Shared (new) — platform tour master
2. Vexperio — catalog
3. GYGVexperio — GYG option mappings
4. ViatorVexperio — Viator option mappings
5. France Shared Schedule — ship dockings
6. Vexperio/Viator/GYG - schedule and pricing — schedule entries
7. Pricing — carrier rows (commission/promo)
8. `sync_option_pricing()` — derives per-option rows from entries + carriers

### Audit trail
- SQLAlchemy `before_flush` / `after_flush` listeners write `change_log` rows for 7 tracked models
- Bulk sync disables via `audit_enabled` ContextVar
- Review comments stored in `note` table (polymorphic: entity_type + entity_id)

---

## Known Issues (Ranked by Priority)

### 🔴 HIGH — "Failed to fetch" on update-pricing (the screenshot bug)

**Root cause confirmed:** NOT a missing `VITE_API_BASE`. The env files are correct:
- `.env` → `https://vexperio-api-752030257772.europe-west1.run.app`
- `.env.production` → same (used on `npm run build`)
- `.env.local` → `/api` (dev proxy only, Vite loads this in dev mode and `.env.production` overrides it in production builds)

**Actual cause:** The Cloud Run API service (`vexperio-api`) is unreachable at the time of the call. This is a network/availability issue, not a code bug. Most likely causes:
- The Cloud Run service scaled to 0 and cold-start timed out
- A transient Cloud SQL connection failure on the API side (Cloud SQL proxy)
- The PATCH /pricing/{id} route itself 500'd (e.g. pricing_id not found, or DB constraint)

**Fix:** Add structured error surfacing: catch HTTP 4xx/5xx responses separately from network errors so the sync issue panel shows "404 · Pricing record not found" instead of just "Failed to fetch".

### 🟠 MEDIUM — `change_details` / `reviewer_comments` half-migrated on Pricing

**Problem:** The `pricing` SQLAlchemy model still has `change_details` (Text) and `reviewer_comments` (Text) columns. These are:
- Still copied into `PricingHistory` snapshots by the pricing router
- Still selected by `v_pending_review` SQL view
- **Not** in `PricingOut` schema (never returned to clients)
- **Not** in `PricingUpdate` schema (can't be set via API)
- Being nulled on every `PATCH /pricing/{id}` (`p.reviewer_comments = None`)
- Being written by Sheets sync (`sync_pricing`) but read by nobody

The `Note` table is the intended replacement (workflow router already uses it), but the transition was left incomplete.

**Fix:** Write a migration that drops `change_details` and `reviewer_comments` from `pricing`, update `v_pending_review` to query the `note` table instead, remove stale references from pricing router and PricingHistory.

### 🟠 MEDIUM — `sync_option_pricing()` silently produces null commission/promo

**Problem:** `sync_option_pricing()` copies commission/promo from "carrier" rows populated by `sync_pricing()`. If the "Pricing" sheet is absent or malformed, carriers are empty and all derived per-option rows get null commission. No warning is logged. Operators won't know until they notice all net prices are wrong.

**Fix:** Count missing carriers and log a warning (or return them in the result dict).

### 🟡 LOW — `_resolve_platform_option_id` silently drops duplicate mappings

**Problem:** In `schedules.py`, when a `vex_option_id` maps to multiple `PlatformOption` rows for the same platform (e.g. same tour option listed on two GYG products), it silently picks `cands[0]`. The other mapping never gets schedule entries.

**Fix:** Log a warning when `len(cands) > 1`.

### 🟡 LOW — `SchedulePlatformEntry` missing `reviewer_comments` column

**Problem:** The workflow router stores reviewer_comments for `schedule_platform_entry` as a `Note`, with the comment "reviewer_comments has no column on SchedulePlatformEntry". But `v_pending_review` selects `spe.reviewer_comments` — this column does NOT exist on the table, which means the view currently errors or returns null silently depending on DB version.

---

## Decision

**Tackle in order:**
1. **Immediate** — Better error surfacing for sync failures (HIGH) — distinguish network errors from HTTP errors in `mirrorToApiResult`; show status code in the sync issues panel.
2. **Next** — Fix `v_pending_review` view crash / `SchedulePlatformEntry.reviewer_comments` column missing (breaks the view).
3. **Then** — Complete the `change_details`/`reviewer_comments` migration on `pricing`.
4. **Background** — Add missing-carrier warning to `sync_option_pricing`.

---

## File Map (key paths)

| File | Purpose |
|------|---------|
| `api/main.py` | FastAPI app, CORS, X-Editor middleware |
| `api/models.py` | SQLAlchemy ORM models |
| `api/schemas.py` | Pydantic I/O schemas |
| `api/history.py` | Audit log listeners |
| `api/routers/pricing.py` | GET/PATCH pricing + history |
| `api/routers/workflow.py` | Review actions, notes, changelog |
| `api/routers/schedules.py` | Dockings, tour schedules, entries |
| `api/routers/sync.py` | POST /sync/pull trigger |
| `google_sheets_sync.py` | 8-step sheet→DB sync orchestrator |
| `schema.sql` | Full DB schema + views + seed |
| `migrations/` | Idempotent ALTER TABLE scripts |
| `excel-addin/src/api.js` | All data layer logic (2700 lines) |
| `excel-addin/src/tab-options.jsx` | Pricing tab UI |
| `excel-addin/src/change-comment.jsx` | Change comment modal + provider |
| `excel-addin/vite.config.js` | Vite build config, dev proxy |
| `excel-addin/.env.production` | Production VITE_API_BASE |
| `excel-addin/Dockerfile` | nginx static server |
| `Dockerfile` | FastAPI uvicorn server |
