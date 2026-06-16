# Test reference — acceptance ID matrix

Source: [FEATURE_SPECIFICATIONS.md](../../excel-addin/FEATURE_SPECIFICATIONS.md) §8. IDs are stable handles for reports.

## Global (G-)

| ID | Criterion |
|----|-----------|
| G-01 | Ribbon open; load without error on required sheets |
| G-02 | Six tabs render with `window.VEX` |
| G-03 | Reload reflects external sheet edits |
| G-04 | Esc closes secondary (no drawer) |
| G-05 | Esc dirty drawer → discard confirm |
| G-06 | Sync issue badge + Retry after API recovery |
| G-07 | Tweaks density/accent without reload |

## Tours (T-)

| ID | Criterion |
|----|-----------|
| T-01 | Search by option ID → parent tour + highlight |
| T-02 | Stats: published/draft/excluded, mapping counts |
| T-03 | Create tour → FS row → reload visible |
| T-04 | Delete tour impact preview; FS rows removed; optional option cascade |

## Mappings (M-)

| ID | Criterion |
|----|-----------|
| M-01 | Listings by platform; PE info-only where applicable |
| M-02 | Link platform option → API; visible after reload |
| M-03 | Remove mapping clears sheet; DELETE when external ID known |

## Schedule (S-)

| ID | Criterion |
|----|-----------|
| S-01 | Dockings group date+ship+port |
| S-02 | Filters narrow dockings; auto-expand |
| S-03 | New/edit schedule persists to FSS after reload |

## Pricing (P-)

| ID | Criterion |
|----|-----------|
| P-01 | No inline price edit controls |
| P-02 | Stats strip matches PRICING counts |
| P-03 | Card expand shows commission (non-Vexperio), promo, net/final prices |
| P-04 | Card expand view-first; kebab → Propose price change |
| P-05 | Unlinked vexOptId warning chip |
| P-06 | VEX chip → Option detail |
| P-07 | Reload refreshes API pricing |
| P-08 | Cross-platform compare strip when ≥2 platforms per tour |
| P-09 | Schedule pricing sub-tab loads sheet rows grouped by date |
| P-10 | Schedule row shows start time + expected price; View departure opens date row |

## Tasks (K-)

| ID | Criterion |
|----|-----------|
| K-01 | Open/Done/All filters per overall status rules |
| K-02 | Local task survives reload (localStorage) |
| K-03 | Data issues counts + navigation links |
| K-04 | Per-item status updates grouping on refresh |

## Overview (O-)

| ID | Criterion |
|----|-----------|
| O-01 | Matrix platform columns correct per tour |
| O-02 | Row click → Tours + selected tour |

## Prototype (R-)

| ID | Criterion |
|----|-----------|
| R-01 | `Vexperio Add-in.html` loads mock `window.VEX`; six tabs |
| R-02 | UX parity demo (writes simulated / none) |

## Reload / sync (R- — integration)

| ID | Criterion |
|----|-----------|
| R-01 | External sheet edit + Reload |
| R-02 | Post-mapping reload consistency |
| R-03 | API failure still saves sheet + sync issue |
| R-04 | Retry clears issue |
| R-05 | Local task persistence |
| R-06 | Debounced `/sync/pull` (optional observability) |

## Recommended release mix

| Change type | Minimum IDs |
|-------------|-------------|
| UI only | G-*, affected tab *, R-01 prototype |
| api.js / sheets | G-*, T/M/S as affected, R-01–R-05 |
| Manifest/deploy | validate, build, smoke.sh, G-01 |
| Docs only | none (unless claiming tested) |

## Out of scope (not failures)

French schedule UI, portal scraping, inline pricing edit, multi-user live sync, full workflow API approval loop, `staleSchedRefs` population — see FEATURE §9.
