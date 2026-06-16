# Documentation examples — Vexperio Excel add-in

## Example 1: Add tab (Schedule → new “Reports” tab — hypothetical)

1. Implement `tab-reports.jsx` + `TABS` entry (UI skill).
2. **FEATURE:** §2 row `reports` / Reports; §6 matrix column; §8 new bullets.
3. **CODE:** §1 layout table + §5 state `tab` union.
4. **APPLICATION:** §5.1 only if executive summary needs mention.
5. **CHANGELOG:** `[Unreleased] Added — Reports tab …`

---

## Example 2: Add drawer (Edit pricing proposal — hypothetical)

1. **FEATURE:** §7 drawer field table; §5.6 task/pricing rules.
2. **CODE:** §5.4 `drawer.kind` row + §9 form table.
3. **INTEGRATION:** only if new `api.js` writer.
4. Skip APPLICATION unless product boundary changes.

---

## Example 3: API change (`PATCH /schedules/{id}` now always called)

1. `rg schedule api.js` — document actual guard (`scheduleId` truthy).
2. **INTEGRATION:** §4.3 writers + §5.2 load graph if needed.
3. **CODE:** §8.2 write matrix footnote.
4. **FEATURE:** §9 remove “sheet-only schedule update” if behavior fixed.
5. **CHANGELOG:** `Changed — schedule edits mirror to API when …`

---

## Example 4: Sheet column (new FS column AH for region)

1. Update `C` / `FS_TOTAL_COLS` in code first.
2. **CODE:** §7.1 column table.
3. **INTEGRATION:** §4.2 parity with `FS_COLS` in Apps Script.
4. **FEATURE:** drawer fields if user-editable.
5. Verify `apps_script_menu-excel.js` `FS_COLS` alignment note in INTEGRATION.

---

## Example 5: README alignment after Vite migration

**Before (wrong):** Architecture diagram only `dialog.js` + `npm start`.

**After (correct):**

- Diagram: ribbon → `functions.js` → `dialog.html` → Vite React (`src/main.jsx`, `app.jsx`).
- Commands: `npm run dev`, `npm run validate`, `npm run build`.
- Links:

```markdown
## Specifications

- [APPLICATION_SPECS.md](./APPLICATION_SPECS.md)
- [FEATURE_SPECIFICATIONS.md](./FEATURE_SPECIFICATIONS.md)
- [CODE_SPECIFICATIONS.md](./CODE_SPECIFICATIONS.md)
- [INTEGRATION_SPECIFICATIONS.md](./INTEGRATION_SPECIFICATIONS.md)
```

- Legacy: one line on `dialog.js` / `getAppHtml()` as deprecated path.
