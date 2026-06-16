# Vexperio Excel Add-in — Cursor Agent Skills

Project skills for the Vexperio Excel add-in (`excel-addin/`) and browser prototype (`vexperio excel add-ins/`). Invoke by name when the task matches the scope column.

| Skill | Invoke when |
|-------|-------------|
| [vexperio-excel-addin-ui](vexperio-excel-addin-ui/SKILL.md) | Editing React UI: `tab-*.jsx`, `components.jsx`, `secondary-pages.jsx`, `tokens.css`, `tweaks-panel.jsx`, or porting UX from the prototype — **not** `api.js` or manifest |
| [vexperio-excel-integration](vexperio-excel-integration/SKILL.md) | `api.js`, `loadVEX`, `mirrorToApi`, sheet I/O, `main.jsx` boot, `functions.js`, shims, manifest, deploy, France Shared sheets, `VEX_RELOAD` |
| [vexperio-excel-addin-test](vexperio-excel-addin-test/SKILL.md) | QA, manual Excel sideload, prototype browser checks, `npm run validate` / `build`, reload/sync verification, acceptance criteria from FEATURE §8 |
| [vexperio-excel-addin-docs](vexperio-excel-addin-docs/SKILL.md) | Updating `APPLICATION_SPECS`, `FEATURE_SPECIFICATIONS`, `CODE_SPECIFICATIONS`, `INTEGRATION_SPECIFICATIONS`, `README`, or `CHANGELOG` |

**Spec SSOT (relative to repo root):** `excel-addin/APPLICATION_SPECS.md`, `FEATURE_SPECIFICATIONS.md`, `CODE_SPECIFICATIONS.md`, `INTEGRATION_SPECIFICATIONS.md`.
