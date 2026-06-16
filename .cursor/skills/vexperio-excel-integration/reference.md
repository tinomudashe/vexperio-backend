# Integration reference — Vexperio Excel add-in

## Local vs cloud (backend summary)

| Layer | Local dev | Cloud (production) |
|-------|-----------|-------------------|
| **Add-in UI** | Vite `https://localhost:3000` (`manifest.local.xml`) | Cloud Run `vexperio-addin` → `https://vexperio-addin-ciffwglwbq-ew.a.run.app` |
| **Structural data** | User’s Excel workbook on disk (Office.js) | Same — workbook is always local to the user |
| **REST API** | See `VITE_API_BASE` below | `https://vexperio-api-752030257772.europe-west1.run.app` |
| **Sheet → DB sync** | `functions.js` POST `/sync/pull` → **cloud API** (hardcoded URL) | Same endpoint |

**`VITE_API_BASE` (Vite precedence: `.env.local` overrides `.env`):**

| File | Value | Effect |
|------|-------|--------|
| `.env` | `https://vexperio-api-…run.app` | Dev talks to **production API** (typical for Mappings/options) |
| `.env.local` | `/api` | Dev uses Vite proxy → `http://localhost:8080` (needs local API running) |
| (fallback in code) | `http://localhost:8000` | If env unset |

**Excel vs API in `loadVEX()`:** sheets → `TOURS`, `MAPPINGS`, `SCHEDULE`, `OPTIONS`; API → `PRICING`, `TASKS`, `/platforms`, `/reference`, bulk platform options.

**Not in this repo:** `vexperio-api` service implementation (separate deploy).

## Write function matrix

| Export | Sheet | API mirror (`mirrorToApi`) |
|--------|-------|----------------------------|
| `appendTourRow` | New FS row A,D,N,AG + core | `POST /tours` |
| `updateTourRow` | Patch A,B,D,AG by vexId | `PATCH /tours/{id}` |
| `deleteTourRows` | Delete all FS rows for vexId; optional VEX options | `DELETE /tours/{id}?cascade_options=` |
| `savePlatformMapping` | Find empty platform slot or append row | via `writeMappingCols` |
| `writeMappingCols` | Platform column range on `_row` | `POST /platforms/{id}/tours` |
| `clearMappingCols` | Blank platform cols | `DELETE /platform-tour` if found |
| `appendOptionRow` | New VEX row | `POST /tours/{id}/options` |
| `updateOptionRow` | Patch E,G,H | `PATCH .../options/{id}` if keys |
| `clearOptionRow` | Clear B:H | `DELETE .../options/{id}` if keys |
| `appendScheduleRow` | New FSS row | `POST /schedules` |
| `updateScheduleRow` | Rewrite A:I | `PATCH /schedules/{id}` **if** `scheduleId` |
| `deleteScheduleRow` | Delete row | `DELETE /schedules/{id}` **if** `scheduleId` |
| `linkPlatformOption` | — | `PATCH /platform-options/{id}` |

## France Shared Schedule columns

| Col | Field |
|-----|-------|
| A | date (ISO from serial) |
| B | ship |
| C | dockingTimes |
| D | port |
| E | start |
| F | tour (name text) |
| G | tourType |
| H | duration |
| I | status |

## Vexperio options sheet

| Col | Field |
|-----|-------|
| A | tourName (formula) |
| B | tourId |
| D | optionId (raw; UI shows `OPT-{raw}`) |
| E | optionName |
| G | ship |
| H | price |

Writes use B, D, E, G, H for mutations.

## `buildPricing` / `buildTasks` notes

- Pricing rows: join API `/pricing` with `REF` shorex/platform names and Excel options for `vexOptId`.
- `date` / `ship` on pricing rows often **empty** in production `buildPricing`.
- Tasks: group `workflow.pricing_changes` by `editor`; merge `loadLocalTasks()` without duplicate IDs.

## ORPHANS (in `loadVEX`)

| Key | Rule |
|-----|------|
| `platformUnlinked` | `PRICING` without `vexOptId`, non-Vexperio, max 20 |
| `vexUnused` | `OPTIONS` where no `SCHEDULE.tour === tourName` |
| `staleSchedRefs` | Always `[]` — not implemented |

## Manifest (production)

| Item | Value |
|------|-------|
| Host | Workbook, ReadWriteDocument |
| APIs | ExcelApi ≥ 1.7, DialogApi ≥ 1.2 |
| Function | `openVexperio` → `functions.html` |
| Local dev | `manifest.local.xml` → `https://localhost:3000` |

Validate: `npm run validate` (office-addin-manifest).

## Deploy / dev

```bash
cd excel-addin
npm run setup      # dev HTTPS certs
npm run validate
npm run dev        # https://localhost:3000
npm run build      # dist/ for container
./deploy.sh        # Cloud Run europe-west1
```

Sideload (Mac): copy manifest to `~/Library/Containers/com.microsoft.Excel/Data/Documents/wef/`.

## RPC / shims (legacy path)

| File | Role |
|------|------|
| `office-shim.js` | `Excel.run` backing for function-file `google.script.run` |
| `dialog-shim.js` | RPC client in dialog; ~64 KB chunking |
| `apps_script_menu-excel.js` | Server functions + `getAppHtml()` (Sheets only) |

Production UI uses **direct** `api.js` + Office.js, not embedded HTML.

## Environment

| Variable | Purpose |
|----------|---------|
| `VITE_API_BASE` | REST root baked at build time |

Dev proxy: `vite.config.js` may map `/api` → backend.
