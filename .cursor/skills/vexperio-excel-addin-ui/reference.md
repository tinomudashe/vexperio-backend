# UI reference — Vexperio Excel add-in

## File map

| File | Role |
|------|------|
| `excel-addin/src/app.jsx` | Shell, tabs, secondary/drawer routing, status bar, sync panel |
| `excel-addin/src/components.jsx` | Primitives, `useCloseGuard`, filters, domain widgets |
| `excel-addin/src/secondary-pages.jsx` | Secondary pages + all drawer forms + `Drawer` |
| `excel-addin/src/tab-tours.jsx` | Tours list + detail |
| `excel-addin/src/tab-mappings.jsx` | Platform listings, link/unlink UX |
| `excel-addin/src/tab-dates.jsx` | Schedule dockings |
| `excel-addin/src/tab-options.jsx` | Pricing matrix (read-only) |
| `excel-addin/src/tab-tasks.jsx` | Task queue, data issues |
| `excel-addin/src/tab-overview.jsx` | Coverage matrix |
| `excel-addin/src/tokens.css` | Design tokens + layout |
| `excel-addin/src/tweaks-panel.jsx` | Density, tab style, accent |
| `vexperio excel add-ins/*` | Mirror of above + `mock-data.js`, `Vexperio Add-in.html` |

## `window.VEX` keys (read-only in UI)

| Key | Used by |
|-----|---------|
| `TOURS` | Tours, Overview |
| `MAPPINGS` | Tours, Mappings, Overview |
| `SCHEDULE`, `DOCKINGS` | Tours, Schedule, DateRowDetail |
| `OPTIONS` | Tours, Mappings pickers, Tasks orphans |
| `PRICING` | Pricing, OptionDetail, Tasks |
| `TASKS`, `ORPHANS` | Tasks |
| `PLATFORMS`, `PORTS`, `SHIPS`, `SHIP_LINES` | Filters, badges, logos |
| `REF` | Rare in UI — writers use in `api.js` |

Schema detail: [CODE_SPECIFICATIONS.md](../../excel-addin/CODE_SPECIFICATIONS.md) §6.

## Component catalog (summary)

| Component | Notes |
|-----------|-------|
| `Ico` | SVG icon set |
| `StatusPill` | Domain status → CSS pill class |
| `PlatBadge` / `PlatDot` | Platform branding |
| `ShipLogo` / `ShipTile` | Cruise line favicons; split ` / ` for combined ships |
| `IdChip` | Monospace IDs (`OPT-*`) |
| `SearchInput` | Controlled search |
| `FilterDrop` | Single/multi; click-outside close |
| `Combobox` | Tour/platform pickers in forms |
| `DateRangePicker` | Schedule tab |
| `Toolbar` | `left` / `right` slots |
| `Section` | Titled block, optional collapse |
| `TabBar` | `tabStyle` from tweaks |
| `Empty` | Zero-state |
| `ConfirmDialog` / `ConfirmAction` | Destructive flows |
| `KebabMenu` | Row overflow |
| `OptionCard` / `OptionRow` | Tour detail |
| `PlatformBlock` | Mapping listing header |
| `makePlatformKebab`, `LinkPicker`, `VexOptionPicker` | Mappings |

Helpers: `tourOptions`, `shipOptions`, `platformOptions`, `fmtDate`, `groupBy`, etc.

## Drawer field quick reference

See [FEATURE_SPECIFICATIONS.md](../../excel-addin/FEATURE_SPECIFICATIONS.md) §7.

| Form | Required highlights |
|------|---------------------|
| New/Edit tour | `vexId` (new), name, shorex, status, port |
| New/Edit mapping | tour, platform, listing ID/name, status, link (GYG/Viator) |
| New/Edit option | tour, option name; ID on create |
| New/Edit schedule | date, ship, port, start, tour name |
| New task | kind, ≥1 row, title |

## Tasks sub-navigation

| Sub-view | Filter rule |
|----------|-------------|
| Open | Pending / changes requested |
| Done | All items approved |
| All | No filter |
| Data issues | `ORPHANS` sections |

## Pricing tab rules

- No `<input>` on price cells.
- Row click → `drawer: { kind: 'newTask', payload: { kind: 'price', preselect: row } }`.
- Missing `vexOptId` → warning chip.

## Sync issues UI

`app.jsx` subscribes via `subscribeSyncIssues` from `api.js`. Panel: kind, summary, error, Retry (`retrySyncIssue`), Dismiss (`clearSyncIssue`).

## Accessibility (current)

| ID | Status |
|----|--------|
| NF-A1 | Confirm dialogs: `role="dialog"`, `aria-modal` |
| NF-A2 | Tweaks: switches / radiogroup |
| NF-A3 | `:focus-visible` on buttons |
| NF-A4 | FilterDrop focuses search on open |
| NF-A5 | Esc hierarchy (see SKILL.md) |
| NF-A6 | **Gap:** table/card row labels |
