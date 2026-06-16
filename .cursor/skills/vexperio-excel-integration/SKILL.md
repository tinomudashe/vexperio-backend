---
name: vexperio-excel-integration
description: >-
  Guides Office.js and API integration for the Vexperio Excel add-in: api.js,
  loadVEX, mirrorToApi, France Shared sheet contracts, main.jsx boot, functions.js,
  shims, manifest, deploy, and VEX_RELOAD. Use when changing workbook I/O, REST
  calls, sync issues, or add-in hosting — not React tab layout.
disable-model-invocation: true
---

# Vexperio Excel Add-in — Integration

## Scope

| In scope | Out of scope |
|----------|--------------|
| `excel-addin/src/api.js`, `main.jsx` | `tab-*.jsx` layout/styling |
| `functions.js`, `functions.html`, shims | Prototype `mock-data.js` |
| `manifest.xml`, `manifest.local.xml`, `deploy.sh` | Feature copy in specs (use docs skill) |

**Specs:** [INTEGRATION_SPECIFICATIONS.md](../../excel-addin/INTEGRATION_SPECIFICATIONS.md) · [CODE_SPECIFICATIONS.md](../../excel-addin/CODE_SPECIFICATIONS.md) §7–8

Detail: [reference.md](reference.md) · [examples.md](examples.md)

---

## `loadVEX()` pipeline

```
Office global present?
  → probeExcelAccess() — workbook name, ExcelApi 1.7
  → Promise.all:
       readTours(), readMappings(), readSchedule(), readOptions()  [Excel]
       GET /platforms, /reference, /pricing, /workflow/pending     [API, safe fallbacks]
  → build PLATFORMS, PRICING, TASKS, DOCKINGS, ORPHANS, REF
  → merge localStorage tasks (vex_local_tasks)
  → window.VEX = VEX
```

**Throws if:** no Office.js, probe fails, or required sheet missing.

**Does not read:** legacy pricing sheets (`Vexperio - schedule and pricing`, etc.) — Pricing tab uses API only.

---

## `Excel.run` rules

| Rule | Detail |
|------|--------|
| Always `await ctx.sync()` | After range writes/deletes |
| Chunked reads | `CHUNK_ROWS = 250` in `sheetValues()` |
| Row indices | `_row` on entities is **1-based** sheet row |
| Deletes | Bottom-up when deleting multiple FS rows for one `vexId` |
| Sheet check | `getItemOrNullObject` — throw friendly error if missing |
| Post-write UI | Callers invoke `window.VEX_RELOAD?.()` after mutations |

**Probe:** `probeExcelAccess()` before bulk load — surfaces host, platform, API version flags.

---

## Sheet anchors

| Constant | Sheet | Data starts | Cols |
|----------|-------|-------------|------|
| `FS_SHEET` | `France Shared (new)` | row **5** | 33 (`FS_TOTAL_COLS`) |
| `FSS_SHEET` | `France Shared Schedule` | row **2** | A–I (9) |
| `VEX_SHEET` | `Vexperio` | row **2** | A–H (8) |

Legacy (Apps Script only, not `loadVEX`): `Schedule`, `*- schedule and pricing` sheets.

---

## `C` / `FS_COLS` parity

`api.js` object `C` (0-based indices) aligns with `apps_script_menu-excel.js` `FS_COLS`:

| Index | Letter | Field |
|-------|--------|-------|
| 0 | A | shorex |
| 1 | B | vexName |
| 2 | C | vexId |
| 3 | D | vexStatus |
| 13 | N | vexLink |
| 15–18 | P–S | Viator name, id, status, link |
| 23–26 | X–AA | GYG name, id, status, link |
| 28–30 | AC–AE | PE name, id, status |
| 32 | AG | port |

**Mappings:** one FS row → up to three `MAPPINGS` objects (non-empty platform ID cells).

**Tours:** duplicate `vexId` rows collapsed — first row wins in `TOURS`.

---

## `mirrorToApi` order

Pattern for every sheet write that syncs to API:

1. **`Excel.run`** — persist to workbook (source of truth).
2. **`ctx.sync()`** — commit Excel mutation.
3. **`mirrorToApi(kind, summary, asyncFn)`** — best-effort REST; failure → `_syncIssues` entry with `retry` closure.
4. **UI `VEX_RELOAD()`** — refresh `window.VEX` (usually from form after step 1–3).

**Excel-first:** Sheet success is never rolled back on API failure.

**Issue shape:** `{ id, when, kind, summary, error, retry }` — UI: `getSyncIssues`, `retrySyncIssue`, `clearSyncIssue`.

---

## Session caches

Cleared by `clearTourCache()` on every `VEX_RELOAD` (`main.jsx` calls it before `loadVEX`):

| Cache | Key | Fetch |
|-------|-----|-------|
| `_tourCache` | tourId | `GET /tours/{id}` |
| `_platMapCache` | tourId | `GET /platforms/2|3/tours?tour_id=` |
| `_scheduleCache` | shorexId | `GET /schedules?shorex_id=` |
| `_scheduleDayCache` | shorexId\|date | narrow schedule query |
| `_dockingCache` | dockingId | `GET /schedules/dockings/{id}` |
| `_allPlatOptCache` | global | bulk GYG+Viator tours |

Also: `invalidatePlatMapCache(tourId)`, `clearAllPlatformOptionsCache()` after mapping/link changes.

---

## Platform IDs

```javascript
PLATFORM_ID_BY_KEY = { GYG: 2, Viator: 3, PE: 4 }
```

| UI key | API platform_id | FS columns |
|--------|-----------------|------------|
| GYG | 2 | X–AA |
| Viator | 3 | P–S |
| PE | 4 | AC–AE (no link col) |

**Link platform option:** `PATCH /platform-options/{id}` with `{ vex_option_id }`.

**REF maps** (from `GET /reference`): `shipIdByName`, `portIdByName`, `shorexIdByName`, `platformsByName` — used when mirroring name-based sheet fields to IDs.

---

## REST endpoints (from `api.js`)

Do not invent paths — grep `api.js` when adding mirrors.

| Method | Path | Used by |
|--------|------|---------|
| GET | `/platforms` | `loadVEX` |
| GET | `/reference` | `loadVEX` (404 OK) |
| GET | `/pricing` | `loadVEX` |
| GET | `/workflow/pending` | `loadVEX` → `buildTasks` |
| POST | `/tours` | `appendTourRow` |
| PATCH | `/tours/{id}` | `updateTourRow` |
| DELETE | `/tours/{id}?cascade_options=` | `deleteTourRows` |
| POST | `/platforms/{id}/tours` | `writeMappingCols` |
| GET | `/platforms/{id}/tours/by-external/{externalId}` | `clearMappingCols` lookup |
| DELETE | `/platform-tours/{id}` | `clearMappingCols` |
| POST/PATCH/DELETE | `/tours/{id}/options[...]` | option writers |
| POST/PATCH/DELETE | `/schedules[...]` | schedule writers (PATCH/DELETE need `scheduleId`) |
| PATCH | `/platform-options/{id}` | `linkPlatformOption` |
| GET | `/tours/{id}`, `/platforms/2|3/tours`, `/schedules?...` | caches / drill-down |

**Base URL:** `import.meta.env.VITE_API_BASE` (default `http://localhost:8000`). Production in `.env`.

**Helpers:** `apiFetch`, `apiFetchSafe`, `apiPost`, `apiPatch`, `apiDelete`.

---

## `VEX_RELOAD`

Registered in `main.jsx` `mount()`:

```javascript
window.VEX_RELOAD = mount;
// clearTourCache() → loadVEX() → renderApp()
```

Toolbar Refresh and post-save forms call `window.VEX_RELOAD?.()`.

---

## Boot hooks (`main.jsx`)

```
dialog.html → office.js → dialog-shim.js → main.jsx
Office.onReady → DialogShim.setupParentMessageHandler() → mount()
```

| Global | Set in |
|--------|--------|
| `window.VEX` | `loadVEX()` |
| `window.VEX_RELOAD` | `mount()` |
| `window.VEX_TWEAK_DEFAULTS` | `main.jsx` |
| `window.DialogShim` | `dialog-shim.js` |

**Function file:** `functions.js` → `displayDialogAsync(origin + '/dialog.html', { height: 92, width: 92, displayInIframe: true })`.

**Workbook sync:** `registerSyncOnChange()` — worksheets `onChanged`, 3s debounce → `POST .../sync/pull` (`source: 'excel-addin'`).

---

## Error checklist

- [ ] Required sheet names spelled exactly (see Sheet anchors).
- [ ] `Excel` global undefined → browser-only open of `dialog.html` fails by design.
- [ ] `probeExcelAccess` failure → check DialogApi / ExcelApi requirements in manifest.
- [ ] API mirror failure → sync issue recorded; sheet still updated.
- [ ] `updateScheduleRow` / `deleteScheduleRow` without `scheduleId` → sheet-only, no PATCH/DELETE.
- [ ] `clearMappingCols` without resolvable external ID → sheet cleared, API DELETE skipped.
- [ ] CORS / `AppDomains` in manifest for API host.
- [ ] Chunk size — reduce `maxRows` if Online timeouts (rare).

---

## Extension checklist

- [ ] New reader: `readX()` + add to `loadVEX` `Promise.all`; document columns in CODE_SPEC §7.
- [ ] New writer: `Excel.run` then `mirrorToApi`; map names via `REF`.
- [ ] New cache: clear in `clearTourCache()` or dedicated invalidator.
- [ ] Manifest: bump VersionOverrides if new URL or domain.
- [ ] Update [INTEGRATION_SPECIFICATIONS.md](../../excel-addin/INTEGRATION_SPECIFICATIONS.md) for contract changes.

---

## Additional resources

- [reference.md](reference.md) — write function matrix, FSS/VEX columns, deploy commands
- [examples.md](examples.md) — mirror failure, mapping write, schedule POST
