---
name: vexperio-excel-addin-ui
description: >-
  Guides React UI work for the Vexperio Excel add-in: tab-*.jsx, components.jsx,
  secondary-pages.jsx, tokens.css, tweaks-panel.jsx, and prototype porting from
  vexperio excel add-ins/. Use when editing presentation, drawers, filters,
  faux Excel chrome, or design tokens. Excludes api.js, manifest, and Office
  integration.
---

# Vexperio Excel Add-in — UI

## Scope

| In scope | Out of scope |
|----------|--------------|
| `excel-addin/src/` React UI (not `api.js`) | Sheet read/write, REST, `mirrorToApi` |
| `vexperio excel add-ins/` prototype (design source) | `manifest.xml`, `functions.js`, shims |
| `tokens.css`, `tweaks-panel.jsx` | Deploy, Cloud Run |

**Production root:** `excel-addin/src/`  
**Prototype root:** `vexperio excel add-ins/` (entry: `Vexperio Add-in.html`)

## Specification pointers

| Doc | Path from this skill |
|-----|----------------------|
| Application (IA, NFRs, Esc) | [APPLICATION_SPECS.md](../../excel-addin/APPLICATION_SPECS.md) |
| Features (tabs, journeys, acceptance) | [FEATURE_SPECIFICATIONS.md](../../excel-addin/FEATURE_SPECIFICATIONS.md) |
| Code (state, components, drawers) | [CODE_SPECIFICATIONS.md](../../excel-addin/CODE_SPECIFICATIONS.md) |
| Integration (prototype boundary only) | [INTEGRATION_SPECIFICATIONS.md](../../excel-addin/INTEGRATION_SPECIFICATIONS.md) §2 |

Deep tables: [reference.md](reference.md) · Scenarios: [examples.md](examples.md)

---

## Prototype vs production

| Concern | Prototype | Production |
|---------|-----------|------------|
| Entry | `Vexperio Add-in.html` | `dialog.html` → Vite → `main.jsx` |
| React | CDN UMD + Babel in browser | Vite bundle |
| Data | `mock-data.js` → static `window.VEX` | `loadVEX()` in `api.js` (read-only in UI layer) |
| Writes | None | Forms call `api.js` exports then `VEX_RELOAD` |
| Pricing `date`/`ship` | Often populated in mocks | Often empty on API rows — UI must tolerate |
| `staleSchedRefs` | Mock may show rows | Always `[]` — hide or label “not implemented” |
| Platform favicons | May use external URLs | `/assets/plat/` under `excel-addin/public/` |
| Tweaks defaults | May differ | `main.jsx`: spacious, underline, excel-green |

**Porting rule:** Change prototype first for stakeholder demos, then copy/sync the same `.jsx` / `tokens.css` into `excel-addin/src/`. Production imports `./api.js`; prototype uses global `window.VEX` only.

---

## App state shape (`app.jsx`)

```javascript
{
  tab: "tours" | "mappings" | "dates" | "options" | "tasks" | "overview",
  selectedTour: string | null,   // vexId when Tours detail open
  secondary: null | { kind, payload },
  drawer: null | { kind, payload },
  taskVersion: number            // bump after NewTaskForm save
}
```

| `tab` id | UI label | Module |
|----------|----------|--------|
| `tours` | Tours | `tab-tours.jsx` |
| `mappings` | Mappings | `tab-mappings.jsx` |
| `dates` | Schedule | `tab-dates.jsx` |
| `options` | Pricing | `tab-options.jsx` |
| `tasks` | Tasks | `tab-tasks.jsx` |
| `overview` | Overview | `tab-overview.jsx` |

- Tab switch: clears `secondary`; Tours keeps `selectedTour` when staying on Tours.
- Data reads: `window.VEX` after load — do not mutate tour lists in tabs without reload (except `TASKS.unshift` from task form).
- Cross-tab navigation: `setState({ tab, selectedTour, secondary, drawer })` — see Overview → Tours pattern in `tab-overview.jsx`.

### Secondary pages

| `kind` | Component | `payload` |
|--------|-----------|-----------|
| `option` | `OptionDetail` | `optionId` string |
| `dateRow` | `DateRowDetail` | `{ date, ship, port, tour, ... }` |

### Drawers (`renderDrawer` in `app.jsx`)

| `kind` | Form |
|--------|------|
| `newTour`, `editTour` | `NewTourForm`, `EditTourForm` |
| `newMapping`, `editMapping` | `NewMappingForm`, `EditMappingForm` |
| `newOption`, `editOption` | `NewOptionForm`, `EditOptionForm` |
| `newSchedule`, `editSchedule` | `NewScheduleForm`, `EditScheduleForm` |
| `newTask` | `NewTaskForm` (`onTaskSaved` bumps `taskVersion`) |
| `departure` | `DepartureView` (read-only) |

Open: `setState(s => ({ ...s, drawer: { kind, payload } }))`. Close: `closeDrawer` or guarded `onClose`.

---

## Esc hierarchy (NF-A5)

Priority (innermost wins first):

1. **Open `ConfirmDialog`** — Esc handled inside dialog; focus on confirm.
2. **Dirty drawer** — `Drawer` capture-phase Esc → `onClose` → `useCloseGuard` → “Discard changes?”
3. **Clean drawer** — Esc closes drawer.
4. **Secondary page** — Window listener in `app.jsx` when `!drawer && secondary` → clear `secondary`.
5. **Tweaks panel** — Panel’s own close/Esc if open (check `tweaks-panel.jsx`).

Do not add a global Esc handler that bypasses `useCloseGuard` on forms.

---

## `useCloseGuard` and `Drawer`

From `components.jsx`:

```javascript
const { guard, overlay } = useCloseGuard(isDirty);
// guard(onClose) — wrap Cancel, backdrop, Drawer onClose
// overlay — render sibling to drawer for confirm UI
```

`Drawer` in `secondary-pages.jsx`: backdrop click and Esc call `onClose` (already guarded by parent). Pattern: `onClose={() => guard(() => props.onClose())}`.

**Read-only drawers** (`DepartureView`): `isDirty` always false — Esc closes immediately.

---

## Drawer patterns

| Pattern | Rule |
|---------|------|
| Width | Default 520px via `.drawer` in `tokens.css` |
| Save | Call `api.js` writer → `await window.VEX_RELOAD?.()` → `onClose` (except `NewTaskForm` → `onSave` / `onTaskSaved`) |
| Delete | `ConfirmAction` or `ConfirmDialog` before destructive API |
| Seed | `newSchedule` accepts `payload.seed` from docking row; `newMapping` accepts `vexId`, `platform` |
| Preselect | `newTask` accepts `kind`, `preselect` from Pricing row click |
| PE mappings | No platform-option link actions — informational only (`tab-mappings.jsx`) |
| Pricing tab | **No inline price edit** — row opens `newTask` with price kind |

---

## `tokens.css` sync

- **Single SSOT for styles:** `excel-addin/src/tokens.css` is canonical; copy to prototype when changing tokens.
- **Body classes** (from `useTweaks` + `app.jsx` `useEffect`): `density-compact|comfortable|spacious`, `accent-excel-green|fluent-blue|graphite`.
- **Token groups:** accent, ink, lines, status pills, platform tints (`--plat-*`), typography, layout (`--row-h`, `--section-gap`).
- **Components:** `.dialog`, `.toolbar`, `.tbl`, `.drawer`, `.statusbar`, `.pill`, `.plat`, `.idchip`.
- **Tab chrome:** `TabBar` reads `tabStyle` (`underline` | `pill`) from tweaks — add CSS for both in `tokens.css`.

After token changes: verify all six tabs + one drawer in production and prototype.

---

## Tab conventions

| Tab | Data keys | UI notes |
|-----|-----------|----------|
| Tours | `TOURS`, `OPTIONS`, `MAPPINGS`, `SCHEDULE` | Search includes option ID; stats bar; detail + drawers |
| Mappings | `MAPPINGS`, bulk platform options fetch | Expand listing; `LinkPicker` / `VexOptionPicker` |
| Schedule | `DOCKINGS`, `SCHEDULE` | Two-level dockings → departures; `DateRangePicker` |
| Pricing | `PRICING` | Read-only table; unlinked `vexOptId` chip |
| Tasks | `TASKS`, `ORPHANS` | Subtabs Open/Done/All/Data issues |
| Overview | `TOURS`, `MAPPINGS` | `PlatDot` matrix; row → Tours + `selectedTour` |

Shared primitives: `Toolbar`, `SearchInput`, `FilterDrop`, `Section`, `Empty`, `StatusPill`, `PlatBadge`, `ShipTile`, `KebabMenu`. Icons via `Ico`.

**Reload:** toolbar Refresh → `window.VEX_RELOAD?.()` on every tab.

---

## Stub inventory (compact)

| Item | Location | UI expectation |
|------|----------|----------------|
| Titlebar Close/Min/Max/Help | `app.jsx` | Decorative — no `closeContainer` |
| Status “synced just now” | `app.jsx` | Static copy |
| `staleSchedRefs` | `ORPHANS` | Empty — Data issues third section empty in prod |
| Task approve API round-trip | `tab-tasks.jsx` | Mostly local state; document gap if extending |
| Table row ARIA | tabs | NF-A6 gap — don’t claim full a11y |
| `externalOptId` on pricing rows | display only | Often blank |

Full list: [CODE_SPECIFICATIONS.md](../../excel-addin/CODE_SPECIFICATIONS.md) §12.

---

## Workflow checklists

### 1. New tab

- [ ] Add `{ id, label }` to `TABS` in `app.jsx`
- [ ] Create `tab-<name>.jsx`; branch in `renderTab()`
- [ ] Add `StatusBar` description string in `app.jsx`
- [ ] Use `window.VEX` keys only (no new loaders in UI files)
- [ ] Update [FEATURE_SPECIFICATIONS.md](../../excel-addin/FEATURE_SPECIFICATIONS.md) tab catalog

### 2. New drawer / form

- [ ] Add `drawer.kind` branch in `renderDrawer` + form in `secondary-pages.jsx`
- [ ] `useCloseGuard` + `Drawer` + field spec in FEATURE §7
- [ ] Save → appropriate `api.js` export → `VEX_RELOAD` (or `onTaskSaved`)
- [ ] Esc/backdrop through `guard()`

### 3. Port prototype → production

- [ ] Diff `vexperio excel add-ins/<file>` vs `excel-addin/src/<file>`
- [ ] Restore `import` from `./api.js` where prototype used globals
- [ ] Replace mock-only actions with real handlers
- [ ] Confirm favicon paths use `/assets/...`

### 4. Token / density change

- [ ] Edit `tokens.css` in production; sync prototype copy
- [ ] Verify `density-*` and `accent-*` on `document.body`
- [ ] Spot-check Tours table + one drawer

### 5. Cross-tab navigation

- [ ] `setState` sets `tab` + `selectedTour` / `secondary` / `drawer` as needed
- [ ] Clear `secondary` when switching tabs (unless spec says otherwise)

---

## Additional resources

- [reference.md](reference.md) — component catalog, drawer field summary, file map
- [examples.md](examples.md) — porting, drawer, and tab scenarios
