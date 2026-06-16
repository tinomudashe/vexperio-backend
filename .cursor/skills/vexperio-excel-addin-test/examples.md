# Test examples — Vexperio Excel add-in

## Example 1: Pre-release gate (integration change)

```bash
cd excel-addin
npm run validate
npm run build
```

Sideload `manifest.local.xml`, open France Shared workbook, run **G-01** through **G-07**, then **M-02** if `api.js` mapping touched.

---

## Example 2: Sync issue R-03 / R-04

1. Point `.env.local` at unreachable host or stop local API.
2. Edit tour in add-in → Save.
3. Confirm row changed in Excel; status bar shows sync issue.
4. Restore API → **Retry** → issue dismissed.

Report: G-06 + R-03 + R-04 Pass/Fail.

---

## Example 3: Prototype-only UX review

1. Open `vexperio excel add-ins/Vexperio Add-in.html`.
2. Run **R-01**: all tabs, open one drawer (no save).
3. Do **not** claim **T-03** (sheet write) on prototype alone.

---

## Example 4: Post-deploy smoke

```bash
.cursor/skills/vexperio-excel-addin-test/scripts/smoke.sh \
  https://vexperio-addin-ciffwglwbq-ew.a.run.app
```

Expect HTTP 200 on `dialog.html`, `manifest.xml`, icon; `healthz` body `ok`.

---

## Example 5: Partial report snippet

| ID | Result | Notes |
|----|--------|-------|
| G-01 | Pass | Excel Mac, manifest.local |
| P-01 | Pass | No inputs in price column |
| K-02 | Pass | T-local id after reload |
| — | N/A | No automated suite in repo |

**Blockers:** none  
**Gaps acknowledged:** staleSchedRefs empty by design
