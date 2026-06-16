---
name: vexperio-excel-addin-docs
description: >-
  Maintains Vexperio Excel add-in documentation: APPLICATION_SPECS,
  FEATURE_SPECIFICATIONS, CODE_SPECIFICATIONS, INTEGRATION_SPECIFICATIONS,
  excel-addin/README.md, and CHANGELOG.md. Use when updating specs after code
  changes, fixing doc drift, or writing release notes. Not for implementing UI
  or api.js — use sibling skills.
disable-model-invocation: true
---

# Vexperio Excel Add-in — Documentation

## Doc hierarchy (SSOT)

| Document | SSOT for | Path |
|----------|----------|------|
| **APPLICATION_SPECS** | Executive summary, architecture, NFRs, glossary, environments, roadmap | [APPLICATION_SPECS.md](../../excel-addin/APPLICATION_SPECS.md) |
| **FEATURE_SPECIFICATIONS** | Tabs, journeys, business rules, drawer fields, **acceptance §8**, out of scope | [FEATURE_SPECIFICATIONS.md](../../excel-addin/FEATURE_SPECIFICATIONS.md) |
| **CODE_SPECIFICATIONS** | Modules, `window.VEX` schemas, components, sheet columns, stubs | [CODE_SPECIFICATIONS.md](../../excel-addin/CODE_SPECIFICATIONS.md) |
| **INTEGRATION_SPECIFICATIONS** | Office.js, manifest, API mirror, deploy, prototype boundary | [INTEGRATION_SPECIFICATIONS.md](../../excel-addin/INTEGRATION_SPECIFICATIONS.md) |
| **README** | Quick start, run locally, deploy smoke, file index | [README.md](../../excel-addin/README.md) |
| **CHANGELOG** | Release notes, unreleased bucket | [CHANGELOG.md](../../excel-addin/CHANGELOG.md) |

**Rule:** Code behavior is truth. Update specs **after** verified behavior — not aspirational features.

Checklists: [reference.md](reference.md) · Scenarios: [examples.md](examples.md)

---

## When to update which file

| Change | Update |
|--------|--------|
| New tab / user-visible feature | FEATURE (+ APPLICATION summary if major); CODE module list |
| New drawer fields / business rule | FEATURE §5–7 |
| New `api.js` endpoint or sheet column | INTEGRATION + CODE §7–8; grep `api.js` for exact paths |
| New React module / state shape | CODE |
| Manifest URL, deploy, env var | INTEGRATION + README |
| Stub removed / wired | CODE §12 + FEATURE out-of-scope if promoted |
| Release shipped | CHANGELOG dated section; README version note if needed |

**Do not duplicate** full column tables in APPLICATION — link to CODE/INTEGRATION.

---

## Prototype folder rules

**Path:** `vexperio excel add-ins/` (sibling of `excel-addin/`)

| Topic | Document in |
|-------|-------------|
| No Office.js, mock `window.VEX` | INTEGRATION §2 |
| UX parity vs production gaps | APPLICATION §11 + FEATURE §10 |
| File sync with `excel-addin/src/` | CODE §11 |

**README must not** imply prototype is production. **FEATURE §8.8** is the prototype acceptance section.

---

## Decision tree

```
User changed code?
├─ No → stop (docs-only request: pick target doc above)
└─ Yes → What layer?
    ├─ UI only (tab/components/tokens)
    │   └─ FEATURE (matrix/journeys) + CODE (components) if new primitives
    ├─ api.js / sheets / manifest
    │   └─ INTEGRATION + CODE; FEATURE if operator-visible behavior
    ├─ Acceptance / QA criteria
    │   └─ FEATURE §8; test skill reference matrix
    └─ Release
        └─ CHANGELOG + README if commands/architecture changed
```

---

## README requirements

[README.md](../../excel-addin/README.md) must reflect **current** stack:

- **React 18 + Vite** SPA in `src/`, entry `dialog.html` → `main.jsx`
- Dev: `npm run dev` (not `npm start`)
- Link to all four `*_SPECS.md` files
- Legacy `dialog.js` / embedded HTML: transitional note only, not primary architecture

---

## CHANGELOG conventions

- Keep **[Unreleased]** at top for in-flight work
- Sections: Added, Changed, Fixed, Removed, Security
- Reference user-facing outcomes, not file lists only

---

## Drift detection (quick)

Before closing a docs task:

- [ ] Tab IDs in FEATURE match `TABS` in `app.jsx`
- [ ] API paths in INTEGRATION match `grep apiFetch api.js`
- [ ] Sheet names match `FS_SHEET` / `FSS_SHEET` / `VEX_SHEET` constants
- [ ] README dev command is `npm run dev`
- [ ] Prototype path uses repo-relative name `vexperio excel add-ins/`

Full checklist: [reference.md](reference.md).

---

## Additional resources

- [reference.md](reference.md) — feature/API/release/drift checklists
- [examples.md](examples.md) — doc update scenarios
