---
name: vexperio-excel-addin-test
description: >-
  Guides manual QA for the Vexperio Excel add-in: FEATURE §8 acceptance criteria,
  Excel sideload, prototype browser checks, npm run validate/build, reload and
  sync-issue tests. Use when verifying releases or writing test reports. The repo
  has no automated unit or E2E tests — document that honestly.
disable-model-invocation: true
---

# Vexperio Excel Add-in — Testing

## Honest scope

| Exists | Does not exist |
|--------|----------------|
| Manual Excel sideload QA | Jest / Vitest / Playwright suites |
| Prototype browser smoke | CI test job for add-in UI |
| `npm run validate` (manifest) | Automated sheet fixture tests |
| `npm run build` (bundle compile) | API contract tests in this repo |
| Optional `scripts/smoke.sh` (HTTP deploy curl) | Regression snapshots |

Treat **FEATURE §8** and tab matrices in [reference.md](reference.md) as the acceptance SSOT.

**Specs:** [FEATURE_SPECIFICATIONS.md](../../excel-addin/FEATURE_SPECIFICATIONS.md) §8 · [APPLICATION_SPECS.md](../../excel-addin/APPLICATION_SPECS.md)

---

## Test pyramid (this repo)

```
                    ┌─────────────────────┐
                    │ Manual Excel E2E    │  ← primary gate (real workbook)
                    └──────────┬──────────┘
              ┌────────────────┴────────────────┐
              │ Prototype browser (mock VEX)   │  ← UX/copy only
              └────────────────┬────────────────┘
        ┌──────────────────────┴──────────────────────┐
        │ npm run validate + build + deploy smoke.sh   │  ← fast gates
        └─────────────────────────────────────────────┘
```

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Canonical workbook | Sheets: `France Shared (new)`, `France Shared Schedule`, `Vexperio`, legacy pricing sheets optional |
| Excel desktop or web | Sideload manifest from `excel-addin/` |
| Dev server | `npm run dev` → `https://localhost:3000` + `manifest.local.xml` |
| API reachable | `VITE_API_BASE` or production API in manifest `AppDomains` |
| Dev certs | `npm run setup` once (Mac trust for localhost) |

**Prototype only:** open `vexperio excel add-ins/Vexperio Add-in.html` — no Excel/API.

---

## Dev server — observable runs (agents + paired testing)

When running tests **with the user**, control the dev server so logs are visible in the Cursor terminal (not a hidden background job).

### Before start

1. **Stop old servers** (avoid stale Vite or zombie port 3000):
   ```bash
   lsof -ti:3000 | xargs kill -9 2>/dev/null || true
   ```
   Or: `bash .cursor/skills/vexperio-excel-addin-test/scripts/dev-server.sh stop`

2. Confirm: `lsof -ti:3000` prints nothing.

### Start (observable)

From repo root:

```bash
cd excel-addin && npm run dev
```

Keep the shell **in the foreground** or as a **background shell you can read** (`terminals/*.txt`). Wait for:

```text
VITE … ready in … ms
➜  Local:   https://localhost:3000/
```

### Verify (agent can run)

```bash
curl -sk -o /dev/null -w "%{http_code}\n" https://localhost:3000/dialog.html   # expect 200
curl -sS -o /dev/null -w "%{http_code}\n" "$VITE_API_BASE/platforms/2/tours"  # expect 200 (from excel-addin/.env)
```

### Local manifest checklist

- Copy after edits: `cp excel-addin/manifest.local.xml ~/Library/Containers/com.microsoft.Excel/Data/Documents/wef/`
- **`manifest.local.xml` must include** both:
  - `https://localhost:3000`
  - `https://vexperio-api-752030257772.europe-west1.run.app` (same host as `VITE_API_BASE` in `.env`)
- User must **restart Excel** after manifest copy.

### Log messages (not always failures)

| Log | Meaning |
|-----|---------|
| `[vite] http proxy error: /platforms` | Something requested `https://localhost:3000/api/...` while **no** backend runs on `:8080`. Production loads use `VITE_API_BASE` directly — often harmless if Mappings still loads options. |
| `Not running inside Excel` in browser | Expected when opening `index.html` outside Excel. |

### Stop after session

```bash
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
```

Helper: [scripts/dev-server.sh](scripts/dev-server.sh) — `stop` | `status` | `start` (foreground `exec npm run dev`).

---

## Global acceptance bullets (§8.1)

- [ ] Ribbon **Open Vexperio** opens dialog; load completes on valid workbook
- [ ] Six tabs render with `window.VEX` populated
- [ ] **Reload** reflects external sheet edits
- [ ] **Esc** closes secondary when no drawer
- [ ] **Esc** on dirty drawer → discard confirm
- [ ] Forced API failure → sync badge; **Retry** after recovery
- [ ] Tweaks change density/accent without reload

Full checklist: [FEATURE_SPECIFICATIONS.md](../../excel-addin/FEATURE_SPECIFICATIONS.md) §8.

---

## Tab test matrices

Use IDs like **G-T-01** (global + tab + item). Full matrix: [reference.md](reference.md).

| Area | ID prefix | §8 section |
|------|-----------|------------|
| Global | G- | 8.1 |
| Tours | T- | 8.2 |
| Mappings | M- | 8.3 |
| Schedule | S- | 8.4 |
| Pricing | P- | 8.5 |
| Tasks | K- | 8.6 |
| Overview | O- | 8.7 |
| Prototype | R- | 8.8 |

---

## Reload / sync tests

| Test | Steps | Pass |
|------|-------|------|
| **R-01 External edit** | Change tour name in FS sheet outside add-in → Reload | Tours list updates |
| **R-02 Cache bust** | Link mapping → Reload | Mappings + Tours counts consistent |
| **R-03 API down** | Stop API or bad `VITE_API_BASE` → save tour | Sheet updates; sync issue appears |
| **R-04 Retry** | Restore API → Retry on issue | Issue clears; optional API row exists |
| **R-05 Local task** | Create task → Reload | Task still in Open (localStorage) |
| **R-06 Pull sync** | Edit sheet → wait 3s+ | Function-file debounced `/sync/pull` (server logs) |

---

## Automated gates (non-UI)

```bash
cd excel-addin
npm run validate   # manifest.xml
npm run build      # Vite production bundle
```

**Deploy smoke** (after Cloud Run deploy):

```bash
.cursor/skills/vexperio-excel-addin-test/scripts/smoke.sh https://YOUR_RUN_URL
```

---

## Task workflow (QA)

1. Copy checklist from [reference.md](reference.md) for affected tab IDs.
2. Run automated gates if integration/manifest touched.
3. Run manual Excel path on **production** build (not prototype-only for sheet writes).
4. Run prototype §8.8 if UI/copy changed.
5. File report using template below.

---

## Known gaps / stubs (do not fail as bugs)

| Gap | Expected behavior |
|-----|-------------------|
| `staleSchedRefs` | Empty in production Data issues |
| Schedule PATCH without `schedule_id` | Sheet-only update |
| Titlebar Close | Decorative |
| Status “synced just now” | Static |
| Pricing `date`/`ship` columns | Often blank |
| Task reviewer API round-trip | Partial — local state dominates |
| No automated tests | Document in every release report |

See [FEATURE_SPECIFICATIONS.md](../../excel-addin/FEATURE_SPECIFICATIONS.md) §9 out of scope.

---

## Test report template

```markdown
# Vexperio Add-in Test Report

**Date:** YYYY-MM-DD
**Build:** commit / Cloud Run URL / local dev
**Tester:**
**Workbook:** (filename)

## Automated
- [ ] npm run validate
- [ ] npm run build
- [ ] smoke.sh (if deployed)

## Manual Excel
| ID | Pass/Fail/Skip | Notes |
|----|----------------|-------|
| G-01 | | |
| T-01 | | |
…

## Prototype (if UI changed)
- [ ] R-01 All tabs render

## Sync / API
- [ ] R-03 R-04

## Blockers

## Notes (gaps acknowledged)
```

---

## Additional resources

- [reference.md](reference.md) — full G/T/M/S/P/K/O/R ID matrix
- [examples.md](examples.md) — sample test sessions
- [scripts/smoke.sh](scripts/smoke.sh) — curl deploy checks
