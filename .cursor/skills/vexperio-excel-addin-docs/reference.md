# Documentation reference — Vexperio Excel add-in

## Feature addition checklist

- [ ] Describe tab in FEATURE §2 catalog (internal ID + UI label)
- [ ] Add user journey in FEATURE §4 if non-trivial
- [ ] Update FEATURE §6 feature matrix row/column
- [ ] Add acceptance bullets in FEATURE §8 (new subsection if needed)
- [ ] CODE: `app.jsx` TABS, new `tab-*.jsx`, state routing
- [ ] APPLICATION §5 summary row if stakeholder-facing
- [ ] INTEGRATION only if new sheet/API
- [ ] Test skill reference matrix (new T-/M-/… IDs)
- [ ] CHANGELOG [Unreleased] Added

## API change checklist

- [ ] Grep `excel-addin/src/api.js` for exact method + path
- [ ] INTEGRATION §4–6 endpoint table
- [ ] CODE §8 write matrix + mirror behavior
- [ ] FEATURE §5 business rules if operator-visible
- [ ] manifest `AppDomains` if new host
- [ ] No invented endpoints in APPLICATION umbrella
- [ ] CHANGELOG [Unreleased] Changed/Fixed

## Release notes template

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- …

### Changed
- …

### Fixed
- …

### Notes
- QA: FEATURE §8 IDs verified: G-01, T-01, …
- Deploy: Cloud Run URL / manifest version
```

Move items from `[Unreleased]` when tagging release.

## Drift detection checklist

| Check | Command / location |
|-------|-------------------|
| Tab IDs | `TABS` in `src/app.jsx` vs FEATURE §2 |
| Drawer kinds | `renderDrawer` in `app.jsx` vs CODE §5.4 |
| REST paths | `rg "api(Fetch\|Post\|Patch\|Delete)" excel-addin/src/api.js` vs INTEGRATION |
| Sheet constants | top of `api.js` vs INTEGRATION §4.1 |
| Esc behavior | `app.jsx` + APPLICATION NF-A5 vs UI skill |
| Stubs | CODE §12 vs FEATURE §9 |
| Scripts | `package.json` vs README (dev, validate, build, deploy) |
| Prototype entry | `Vexperio Add-in.html` exists under `vexperio excel add-ins/` |

## Cross-links from skills

| Skill | Spec sections to keep aligned |
|-------|------------------------------|
| vexperio-excel-addin-ui | FEATURE §3–7, CODE §4–5, APPLICATION §6.4 |
| vexperio-excel-integration | INTEGRATION, CODE §7–8 |
| vexperio-excel-addin-test | FEATURE §8–9 |

## Paths (repo-relative)

| Asset | Path |
|-------|------|
| Production add-in | `excel-addin/` |
| Prototype | `vexperio excel add-ins/` |
| Cursor skills index | `.cursor/skills/README.md` |
| Legacy Apps Script (reference) | `apps_script_menu-excel.js` (repo root or vendored in add-in) |

## Out of scope registry

Maintain in FEATURE §9 — do not document as bugs: `staleSchedRefs`, inline pricing edit, titlebar close wiring, full workflow API approval, automated test suite absence.
