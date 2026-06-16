"""
One-time setup: write cross-sheet VLOOKUP formulas and dropdowns into Google Sheets.
Run once (or re-run safely — formulas are idempotent).

Run: python setup_sheet_formulas.py
"""
import os
import requests as http_lib
import gspread
from google.oauth2.service_account import Credentials
from google.auth.transport.requests import Request as GoogleAuthRequest
from dotenv import load_dotenv

load_dotenv()

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive",
]

CREDENTIALS_PATH = os.getenv("GOOGLE_CREDENTIALS_PATH", "credentials.json")
SPREADSHEET_ID   = os.getenv("GOOGLE_SPREADSHEET_ID", "")

FS  = "'France Shared (new)'"
LHP = "'Le Havre-Privates'"


# ── formula helpers ───────────────────────────────────────────────────────────

def fe(formula: str) -> str:
    return f'=IFERROR({formula},"")'

def lookup(key_cell: str, sheet: str, return_col: str, lookup_col: str) -> str:
    return fe(f"INDEX({sheet}!{return_col}:{return_col},MATCH({key_cell},{sheet}!{lookup_col}:{lookup_col},0))")

def lookup_two(key_cell, s1, rc1, lc1, s2, rc2, lc2) -> str:
    """Try sheet 1 first, fall back to sheet 2."""
    return f'=IFERROR(INDEX({s1}!{rc1}:{rc1},MATCH({key_cell},{s1}!{lc1}:{lc1},0)),IFERROR(INDEX({s2}!{rc2}:{rc2},MATCH({key_cell},{s2}!{lc2}:{lc2},0)),""))'

def col_formulas(ws, col_letter: str, formula_fn, key_col_idx: int, start_row: int = 2) -> list:
    rows = ws.get_all_values()
    result = []
    for i in range(start_row - 1, len(rows)):
        r = i + 1
        if rows[i][key_col_idx].strip():
            result.append((f"{col_letter}{r}", formula_fn(r)))
    return result

def apply(ws, updates: list, label: str):
    if not updates:
        print(f"  {label}: nothing to update")
        return
    ws.batch_update(
        [{"range": cell, "values": [[formula]]} for cell, formula in updates],
        value_input_option="USER_ENTERED",
    )
    print(f"  {label}: {len(updates)} cells written")


# ── column insertion ──────────────────────────────────────────────────────────

def insert_column(sh, ws, after_col_idx: int):
    """Insert a blank column after after_col_idx (0-based)."""
    sh.batch_update({"requests": [{
        "insertDimension": {
            "range": {
                "sheetId": ws._properties["sheetId"],
                "dimension": "COLUMNS",
                "startIndex": after_col_idx + 1,
                "endIndex": after_col_idx + 2,
            },
            "inheritFromBefore": False,
        }
    }]})


# ── data validation (dropdown) ────────────────────────────────────────────────

def _get_fresh_token(sh):
    """Return a valid Bearer token from the gspread client's credentials."""
    # In gspread 6.x, sh.client IS the HTTPClient; credentials are in .auth
    creds = sh.client.auth
    if not creds.valid:
        creds.refresh(GoogleAuthRequest())
    return creds.token


def get_sheet_tables(sh, ws):
    """Return the list of Table objects defined on ws, via REST API."""
    url = f"https://sheets.googleapis.com/v4/spreadsheets/{sh.id}"
    r = http_lib.get(
        url,
        params={"fields": "sheets(properties/sheetId,tables)"},
        headers={"Authorization": f"Bearer {_get_fresh_token(sh)}"},
    )
    r.raise_for_status()
    target_id = ws._properties["sheetId"]
    for sheet in r.json().get("sheets", []):
        if sheet["properties"]["sheetId"] == target_id:
            return sheet.get("tables", [])
    return []


def get_option_ids_for_dropdown(sh, source: str) -> list:
    """
    Resolve a source like "Vexperio!$D$2:$D$200" into a list of non-empty string values
    so they can be used as ONE_OF_LIST items in a Table column dropdown.
    """
    # parse  SheetName!$COL$ROW:$COL$ROW
    import re
    m = re.match(r"([^!]+)!\\\$([A-Z]+)\\\$(\d+):\\\$([A-Z]+)\\\$(\d+)", source)
    if not m:
        # try without escaped $
        m = re.match(r"([^!]+)!\$([A-Z]+)\$(\d+):\$([A-Z]+)\$(\d+)", source)
    if not m:
        return []
    sheet_name, col_letter_s, start_r, _col2, end_r = m.groups()
    ws_src = sh.worksheet(sheet_name)
    col_idx = col_letter_to_idx(col_letter_s) + 1  # gspread col_values is 1-based
    all_vals = ws_src.col_values(col_idx)
    start = int(start_r) - 1   # 0-based
    end   = int(end_r)
    return [v.strip() for v in all_vals[start:end] if v.strip()]


def set_table_column_dropdown(sh, ws, col_letter: str, source: str) -> bool:
    """
    For sheets that use the Google Sheets Tables feature, set a dropdown by updating
    the Table's columnProperties (the only way the API allows it on typed columns).
    Returns True if handled, False if the column is not inside a Table.
    """
    col_idx = col_letter_to_idx(col_letter)
    tables = get_sheet_tables(sh, ws)
    if not tables:
        return False

    for table in tables:
        tr = table.get("range", {})
        if not (tr.get("startColumnIndex", 0) <= col_idx < tr.get("endColumnIndex", 0)):
            continue  # this column is not inside this table

        table_id = table.get("tableId")
        col_props = table.get("columnProperties", [])

        option_ids = get_option_ids_for_dropdown(sh, source)
        if not option_ids:
            print(f"  ⚠️  No option IDs found from {source} — skipping dropdown")
            return True  # still "handled" — don't fall through to setDataValidation

        new_validation = {
            "condition": {
                "type": "ONE_OF_LIST",
                "values": [{"userEnteredValue": v} for v in option_ids],
            },
        }

        # Build updated columnProperties list
        new_props = []
        found = False
        for cp in col_props:
            # first column may have no columnIndex key (defaults to 0)
            idx = cp.get("columnIndex", 0)
            if idx == col_idx:
                c = dict(cp)
                c["columnType"] = "DROPDOWN"
                c["dataValidationRule"] = new_validation
                new_props.append(c)
                found = True
            else:
                new_props.append(dict(cp))

        if not found:
            new_props.append({
                "columnIndex": col_idx,
                "columnType": "DROPDOWN",
                "dataValidationRule": new_validation,
            })

        try:
            sh.batch_update({"requests": [{
                "updateTable": {
                    "table": {"tableId": table_id, "columnProperties": new_props},
                    "fields": "columnProperties",
                }
            }]})
            print(f"  Dropdown set on {col_letter} via Table columnProperties from {source}")
            return True
        except Exception as e:
            print(f"  Could not update Table columnProperties for {col_letter}: {e}")

    return False


def set_dropdown_from_range(sh, ws, col_letter: str, start_row: int, end_row: int, source: str):
    """
    Set a dropdown on col_letter rows start_row:end_row pulling values from source range.
    If the column is inside a Google Sheets Table, uses updateTable instead of setDataValidation.
    source example: "Vexperio!$D$2:$D$200"
    """
    # Try Table-aware path first
    if set_table_column_dropdown(sh, ws, col_letter, source):
        return

    # Fallback: regular setDataValidation for non-Table columns
    col_idx = col_letter_to_idx(col_letter)
    val_range = {
        "sheetId": ws._properties["sheetId"],
        "startRowIndex": start_row - 1,
        "endRowIndex": end_row,
        "startColumnIndex": col_idx,
        "endColumnIndex": col_idx + 1,
    }
    try:
        sh.batch_update({"requests": [{
            "setDataValidation": {
                "range": val_range,
                "rule": {
                    "condition": {
                        "type": "ONE_OF_RANGE",
                        "values": [{"userEnteredValue": f"={source}"}],
                    },
                    "showCustomUi": True,
                    "strict": False,
                }
            }
        }]})
        print(f"  Dropdown set on {col_letter}{start_row}:{col_letter}{end_row} from {source}")
    except Exception as e:
        print(f"  ⚠️  Dropdown on {col_letter} failed: {e}")


def col_letter_to_idx(letter: str) -> int:
    """Convert column letter(s) to 0-based index. A=0, Z=25, AA=26 ..."""
    letter = letter.upper()
    idx = 0
    for ch in letter:
        idx = idx * 26 + (ord(ch) - ord('A') + 1)
    return idx - 1


# ── GYGVexperio ──────────────────────────────────────────────────────────────
#
# Current layout:
#   A  GYG Tour Name   B  GYG Tour ID   C  GYG Option Name   D  GYG Option ID
#   E  Vex Option ID   F  Vex Option Name   G  Vex Price
#   H  Shore Name   I  Link   J  Ship Name
#
# After this script:
#   A  GYG Tour Name (formula ← France Shared / Le Havre-Privates via B)
#   B  GYG Tour ID   (manual — entry point)
#   C  GYG Option Name   (manual)
#   D  GYG Option ID     (manual)
#   E  Vex Tour ID  (NEW col — formula ← France Shared / Le Havre-Privates via B)
#   F  Vex Option ID     (dropdown from Vexperio options)
#   G  Vex Option Name   (formula ← Vexperio via F)
#   H  Vex Price         (formula ← Vexperio via F)
#   I  Shore Name        (formula ← France Shared / Le Havre-Privates via B)
#   J  Link              (formula ← France Shared / Le Havre-Privates via B)
#   K  Ship Name         (manual)

def setup_gyg_vexperio(sh):
    ws = sh.worksheet("GYGVexperio")
    rows = ws.get_all_values()
    n = len(rows)

    # 1. Insert new column E for Vex Tour ID (after col D, index 3)
    #    Only insert if header row doesn't already have it
    if rows[0][4] != "Vex Tour ID":
        print("  GYGVexperio: inserting Vex Tour ID column at E")
        insert_column(sh, ws, after_col_idx=3)
        ws.update([["Vex Tour ID"]], "E1")
        ws = sh.worksheet("GYGVexperio")   # refresh after insert
        rows = ws.get_all_values()
        n = len(rows)
    else:
        print("  GYGVexperio: Vex Tour ID column already exists")

    # After insert: E=VexTourID(new), F=VexOptionID, G=VexOptionName, H=VexPrice, I=ShoreName, J=Link, K=ShipName

    updates = []

    # A = GYG tour name ← France Shared (new) col X via GYG Tour ID (Y), fallback Le Havre-Privates col K via J
    updates += col_formulas(ws, "A",
        lambda r: lookup_two(f"B{r}", FS, "X", "Y", LHP, "K", "J"),
        key_col_idx=1)

    # E = Vex Tour ID ← Vexperio col B via Vex Option ID (F)
    updates += col_formulas(ws, "E",
        lambda r: fe(f'INDEX(Vexperio!B:B,MATCH(IFERROR(VALUE(F{r}),F{r}),Vexperio!D:D,0))'),
        key_col_idx=3)

    # G = Vex Option Name ← Vexperio col E via Vex Option ID (F)
    # DROPDOWN chips store values as text; Vexperio!D is numeric — use VALUE() to coerce.
    updates += col_formulas(ws, "G",
        lambda r: fe(f'INDEX(Vexperio!E:E,MATCH(IFERROR(VALUE(F{r}),F{r}),Vexperio!D:D,0))'),
        key_col_idx=3)   # col D = GYG Option ID

    # H = Vex Price ← Vexperio col H via Vex Option ID (F)
    updates += col_formulas(ws, "H",
        lambda r: fe(f'INDEX(Vexperio!H:H,MATCH(IFERROR(VALUE(F{r}),F{r}),Vexperio!D:D,0))'),
        key_col_idx=3)

    # I = Shore Name ← Vexperio col C via Vex Option ID (F)
    updates += col_formulas(ws, "I",
        lambda r: fe(f'INDEX(Vexperio!C:C,MATCH(IFERROR(VALUE(F{r}),F{r}),Vexperio!D:D,0))'),
        key_col_idx=3)

    # J = Link ← France Shared col AA via GYG Tour ID (Y), fallback Le Havre-Privates col M via J
    updates += col_formulas(ws, "J",
        lambda r: lookup_two(f"B{r}", FS, "AA", "Y", LHP, "M", "J"),
        key_col_idx=1)

    apply(ws, updates, "GYGVexperio formulas")

    # F = Vex Option ID → dropdown from Vexperio option IDs
    set_dropdown_from_range(sh, ws, "F", 2, n, "Vexperio!$D$2:$D$200")


# ── ViatorVexperio ────────────────────────────────────────────────────────────
#
# Current layout:
#   A  Viator Tour Name   B  Viator Tour ID   C  Viator Option Name
#   D  Vex Tour ID        E  Vex Option ID    F  Vex Option Name
#   G  ShorEx Name        H  Link             I  Ship Name
#
# After this script:
#   A  Viator Tour Name (formula ← France Shared / Le Havre-Privates via B)
#   B  Viator Tour ID   (manual)
#   C  Viator Option Name (manual)
#   D  Vex Tour ID      (formula ← France Shared / Le Havre-Privates via B)
#   E  Vex Option ID    (dropdown from Vexperio options)
#   F  Vex Option Name  (formula ← Vexperio via E)
#   G  ShorEx Name      (formula ← France Shared / Le Havre-Privates via B)
#   H  Link             (formula ← France Shared / Le Havre-Privates via B)
#   I  Ship Name        (manual)

def setup_viator_vexperio(sh):
    ws = sh.worksheet("ViatorVexperio")
    rows = ws.get_all_values()
    n = len(rows)

    updates = []

    # A = Viator tour name ← France Shared col P via Viator Tour ID (Q), fallback Le Havre-Privates col G via F
    updates += col_formulas(ws, "A",
        lambda r: lookup_two(f"B{r}", FS, "P", "Q", LHP, "G", "F"),
        key_col_idx=1)

    # D = Vex Tour ID ← Vexperio col B via Vex Option ID (E)
    updates += col_formulas(ws, "D",
        lambda r: fe(f'INDEX(Vexperio!B:B,MATCH(IFERROR(VALUE(E{r}),E{r}),Vexperio!D:D,0))'),
        key_col_idx=2)

    # F = Vex Option Name ← Vexperio col E via Vex Option ID (E)
    # DROPDOWN chips store as text; Vexperio!D is numeric — coerce with VALUE().
    updates += col_formulas(ws, "F",
        lambda r: fe(f'INDEX(Vexperio!E:E,MATCH(IFERROR(VALUE(E{r}),E{r}),Vexperio!D:D,0))'),
        key_col_idx=2)   # col C = Viator Option Name

    # G = Shore Name ← Vexperio col C via Vex Option ID (E)
    updates += col_formulas(ws, "G",
        lambda r: fe(f'INDEX(Vexperio!C:C,MATCH(IFERROR(VALUE(E{r}),E{r}),Vexperio!D:D,0))'),
        key_col_idx=2)

    # H = Link ← France Shared col S via Viator Tour ID (Q), fallback Le Havre-Privates col I via F
    updates += col_formulas(ws, "H",
        lambda r: lookup_two(f"B{r}", FS, "S", "Q", LHP, "I", "F"),
        key_col_idx=1)

    apply(ws, updates, "ViatorVexperio formulas")

    # E = Vex Option ID → dropdown from Vexperio option IDs
    set_dropdown_from_range(sh, ws, "E", 2, n, "Vexperio!$D$2:$D$200")


# ── Vexperio catalog ──────────────────────────────────────────────────────────
# Key: B = Tour ID
# Auto-fill: A (Tour Name), C (ShorEx), F (Status) from France Shared (new)

def setup_vexperio(sh):
    ws = sh.worksheet("Vexperio")
    rows = ws.get_all_values()
    updates = []

    # A = Tour name ← France Shared col B via Tour ID (C)
    updates += col_formulas(ws, "A",
        lambda r: lookup(f"B{r}", FS, "B", "C"),
        key_col_idx=1)

    # C = Shore excursion ← France Shared col A via Tour ID (C)
    updates += col_formulas(ws, "C",
        lambda r: lookup(f"B{r}", FS, "A", "C"),
        key_col_idx=1)

    # F = Status ← France Shared col D via Tour ID (C)
    updates += col_formulas(ws, "F",
        lambda r: lookup(f"B{r}", FS, "D", "C"),
        key_col_idx=1)

    apply(ws, updates, "Vexperio")


# ── GYG schedule and pricing ──────────────────────────────────────────────────
# Key: H = GYG Option ID (idx 7)
# Auto-fill: E (ShorEx), F (Tour Name), G (Option Name), I (Vex Option ID), D (Port)

def setup_gyg_schedule(sh):
    ws = sh.worksheet("GYG - schedule and pricing")
    rows = ws.get_all_values()
    updates = []

    # E = Shore name ← GYGVexperio col I via GYG Option ID (D)
    updates += col_formulas(ws, "E",
        lambda r: lookup(f"H{r}", "GYGVexperio", "I", "D"),
        key_col_idx=7)

    # F = GYG tour name ← GYGVexperio col A via GYG Option ID (D)
    updates += col_formulas(ws, "F",
        lambda r: lookup(f"H{r}", "GYGVexperio", "A", "D"),
        key_col_idx=7)

    # G = GYG option name ← GYGVexperio col C via GYG Option ID (D)
    updates += col_formulas(ws, "G",
        lambda r: lookup(f"H{r}", "GYGVexperio", "C", "D"),
        key_col_idx=7)

    # I = Vex option ID ← GYGVexperio col F via GYG Option ID (D)
    updates += col_formulas(ws, "I",
        lambda r: lookup(f"H{r}", "GYGVexperio", "F", "D"),
        key_col_idx=7)

    # D = Port ← France Shared Schedule col D via Date(A)+Ship(B) match
    updates += col_formulas(ws, "D",
        lambda r: f'=IFERROR(INDEX(\'France Shared Schedule\'!D:D,MATCH(A{r}&B{r},\'France Shared Schedule\'!A:A&\'France Shared Schedule\'!B:B,0)),"")',
        key_col_idx=0)

    apply(ws, updates, "GYG schedule")


# ── Viator schedule and pricing ───────────────────────────────────────────────
# Key: H = Viator Tour ID (idx 7)
# Auto-fill: E (ShorEx), F (Tour Name), G (Option Name), I (Vex Option ID), D (Port)

def setup_viator_schedule(sh):
    ws = sh.worksheet("Viator - schedule and pricing")
    rows = ws.get_all_values()
    updates = []

    # E = Shore name ← ViatorVexperio col G via Viator Tour ID (B)
    updates += col_formulas(ws, "E",
        lambda r: lookup(f"H{r}", "ViatorVexperio", "G", "B"),
        key_col_idx=7)

    # F = Viator tour name ← ViatorVexperio col A via Viator Tour ID (B)
    updates += col_formulas(ws, "F",
        lambda r: lookup(f"H{r}", "ViatorVexperio", "A", "B"),
        key_col_idx=7)

    # G = Viator option name ← ViatorVexperio col C via Viator Tour ID (B)
    updates += col_formulas(ws, "G",
        lambda r: lookup(f"H{r}", "ViatorVexperio", "C", "B"),
        key_col_idx=7)

    # I = Vex option ID ← ViatorVexperio col E via Viator Tour ID (B)
    updates += col_formulas(ws, "I",
        lambda r: lookup(f"H{r}", "ViatorVexperio", "E", "B"),
        key_col_idx=7)

    # D = Port ← France Shared Schedule
    updates += col_formulas(ws, "D",
        lambda r: f'=IFERROR(INDEX(\'France Shared Schedule\'!D:D,MATCH(A{r}&B{r},\'France Shared Schedule\'!A:A&\'France Shared Schedule\'!B:B,0)),"")',
        key_col_idx=0)

    apply(ws, updates, "Viator schedule")


# ── Vexperio schedule and pricing ─────────────────────────────────────────────
# Key: H = Vex Option ID (idx 7)

def setup_vex_schedule(sh):
    ws = sh.worksheet("Vexperio - schedule and pricing")
    rows = ws.get_all_values()
    updates = []

    # E = Shore name ← Vexperio col C via Option ID (D)
    updates += col_formulas(ws, "E",
        lambda r: lookup(f"H{r}", "Vexperio", "C", "D"),
        key_col_idx=7)

    # F = Tour name ← Vexperio col A via Option ID (D)
    updates += col_formulas(ws, "F",
        lambda r: lookup(f"H{r}", "Vexperio", "A", "D"),
        key_col_idx=7)

    # G = Option name ← Vexperio col E via Option ID (D)
    updates += col_formulas(ws, "G",
        lambda r: lookup(f"H{r}", "Vexperio", "E", "D"),
        key_col_idx=7)

    # D = Port ← France Shared Schedule
    updates += col_formulas(ws, "D",
        lambda r: f'=IFERROR(INDEX(\'France Shared Schedule\'!D:D,MATCH(A{r}&B{r},\'France Shared Schedule\'!A:A&\'France Shared Schedule\'!B:B,0)),"")',
        key_col_idx=0)

    apply(ws, updates, "Vexperio schedule")


# ── Pricing ───────────────────────────────────────────────────────────────────
# Key: C = Platform Tour ID, D = Platform
# Auto-fill: B (Platform Name), K (Link), G (Commission %)

def setup_pricing(sh):
    ws = sh.worksheet("Pricing")
    rows = ws.get_all_values()
    updates = []

    for i in range(1, len(rows)):
        r = i + 1
        platform_id = rows[i][2].strip()   # col C
        platform    = rows[i][3].strip()   # col D
        if not platform_id or not platform:
            continue

        p = platform.lower()

        if "vexperio" in p:
            name_formula  = lookup(f"C{r}", FS, "B", "C")
            link_formula  = lookup(f"C{r}", FS, "N", "C")
            comm_formula  = ""   # Vexperio has no platform commission
        elif "getyourguide" in p or "gyg" in p:
            name_formula  = lookup_two(f"C{r}", FS, "X", "Y", LHP, "K", "J")
            link_formula  = lookup_two(f"C{r}", FS, "AA", "Y", LHP, "M", "J")
            comm_formula  = lookup_two(f"C{r}", FS, "I", "Y", LHP, "I", "J")   # col I = GYG com%
        elif "viator" in p:
            name_formula  = lookup_two(f"C{r}", FS, "P", "Q", LHP, "G", "F")
            link_formula  = lookup_two(f"C{r}", FS, "S", "Q", LHP, "I", "F")
            comm_formula  = lookup_two(f"C{r}", FS, "U", "Q", LHP, "U", "F")   # col U = Viator com%
        elif "expedition" in p or " pe" in p:
            name_formula  = lookup_two(f"C{r}", FS, "AC", "AD", LHP, "P", "O")
            link_formula  = ""
            comm_formula  = lookup_two(f"C{r}", FS, "H", "AD", LHP, "H", "O") # col H = PE com%
        else:
            continue

        updates.append((f"B{r}", name_formula))
        if link_formula:
            updates.append((f"K{r}", link_formula))
        if comm_formula:
            updates.append((f"G{r}", comm_formula))

    apply(ws, updates, "Pricing")


# ── main ──────────────────────────────────────────────────────────────────────

def run():
    print("Connecting to Google Sheets…")
    creds = Credentials.from_service_account_file(CREDENTIALS_PATH, scopes=SCOPES)
    gc = gspread.authorize(creds)
    sh = gc.open_by_key(SPREADSHEET_ID)

    print("\nApplying formulas and dropdowns…\n")
    setup_gyg_vexperio(sh)
    setup_viator_vexperio(sh)
    setup_vexperio(sh)
    setup_gyg_schedule(sh)
    setup_viator_schedule(sh)
    setup_vex_schedule(sh)
    setup_pricing(sh)

    print("\n✓ Done. Sheets are now fully linked.")
    print("  Edit France Shared (new) → all sheets update automatically.")
    print("  Vex Option ID columns now have dropdowns in GYGVexperio and ViatorVexperio.")


if __name__ == "__main__":
    run()
