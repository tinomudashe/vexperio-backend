"""
One-time import: 2026_France_Mapping-May.xlsx → PostgreSQL
Run: python import_excel.py [path/to/file.xlsx]
"""
import sys
import re
import pandas as pd
from datetime import time
from sqlalchemy.orm import Session
from sqlalchemy.dialects.postgresql import insert as pg_insert
from api.database import engine, SessionLocal
from api import models

EXCEL_PATH = sys.argv[1] if len(sys.argv) > 1 else "2026_France_Mapping-May.xlsx"


def clean_str(v) -> str | None:
    if pd.isna(v) or str(v).strip() in ("—", "-", "nan", ""):
        return None
    return str(v).strip()


def clean_price(v) -> float | None:
    s = clean_str(v)
    if s is None:
        return None
    try:
        return float(s)
    except ValueError:
        return None


def parse_dock_times(v: str) -> tuple[time | None, time | None]:
    """Parse '07:00-19:00' → (time(7,0), time(19,0))"""
    s = clean_str(v)
    if not s:
        return None, None
    m = re.match(r"(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})", s)
    if m:
        return time(int(m.group(1)), int(m.group(2))), time(int(m.group(3)), int(m.group(4)))
    return None, None


def upsert_ship(db: Session, name: str) -> int:
    name = name.strip()
    obj = db.query(models.Ship).filter_by(name=name).first()
    if not obj:
        obj = models.Ship(name=name)
        db.add(obj)
        db.flush()
    return obj.ship_id


def get_shorex_id(db: Session, name: str) -> int | None:
    s = clean_str(name)
    if not s:
        return None
    obj = db.query(models.ShoreExcursion).filter_by(name=s).first()
    return obj.shorex_id if obj else None


def get_platform_id(db: Session, name: str) -> int | None:
    name_map = {
        "vexperio": "Vexperio",
        "getyourguide": "GetYourGuide",
        "gyg": "GetYourGuide",
        "viator": "Viator",
        "pe": "Project Expedition",
        "project expedition": "Project Expedition",
    }
    canonical = name_map.get(name.lower().strip(), name.strip())
    obj = db.query(models.Platform).filter_by(name=canonical).first()
    return obj.platform_id if obj else None


# ─────────────────────────────────────────────────────────────────────────────
# 1. VEXPERIO CATALOG  →  tour + tour_option + ship
# ─────────────────────────────────────────────────────────────────────────────

def import_vexperio(db: Session, xl: pd.ExcelFile):
    print("  Importing Vexperio catalog...")
    df = xl.parse("Vexperio")
    df.columns = ["tour_name", "tour_id", "shorex_name", "option_id", "option_name",
                  "status", "private", "vex_price", "link", "ship_name"]
    df = df.dropna(subset=["tour_id", "option_id"])
    df["tour_id"] = df["tour_id"].astype(int)
    df["option_id"] = df["option_id"].astype(int)

    seen_tours = set()
    seen_options = set()

    for _, row in df.iterrows():
        shorex_id = get_shorex_id(db, row["shorex_name"])

        # tour
        tid = int(row["tour_id"])
        if tid not in seen_tours:
            exists = db.query(models.Tour).filter_by(tour_id=tid).first()
            if not exists:
                db.add(models.Tour(
                    tour_id=tid,
                    shorex_id=shorex_id,
                    name=str(row["tour_name"]).strip(),
                    status=str(row["status"]).strip() if clean_str(row["status"]) else "Draft",
                    link=clean_str(row["link"]),
                ))
                db.flush()
            seen_tours.add(tid)

        # ship
        ship_name = clean_str(row["ship_name"])
        ship_id = None
        if ship_name and ship_name.lower() not in ("combined tour", "nan"):
            ship_id = upsert_ship(db, ship_name)

        # option (skip duplicates — same option_id can repeat in sheet at different prices)
        oid = int(row["option_id"])
        if oid not in seen_options:
            exists = db.query(models.TourOption).filter_by(option_id=oid).first()
            if not exists:
                db.add(models.TourOption(
                    option_id=oid,
                    tour_id=tid,
                    name=str(row["option_name"]).strip(),
                    is_private=(str(row["private"]).strip().lower() == "yes"),
                    ship_id=ship_id,
                    base_price=clean_price(row["vex_price"]),
                    link=clean_str(row["link"]),
                ))
                db.flush()
            seen_options.add(oid)

    db.commit()
    print(f"    → {len(seen_tours)} tours, {len(seen_options)} options")


# ─────────────────────────────────────────────────────────────────────────────
# 2. GYG PLATFORM TOURS & OPTIONS
# ─────────────────────────────────────────────────────────────────────────────

def import_gyg(db: Session, xl: pd.ExcelFile):
    print("  Importing GYG mappings...")
    df = xl.parse("GYGVexperio")
    df.columns = ["gyg_tour_name", "gyg_tour_id", "gyg_option_name", "gyg_option_id",
                  "vex_option_id", "vex_option_name", "vex_price", "shore_name", "link", "ship_name"]
    df = df.dropna(subset=["gyg_tour_id"])

    platform_id = get_platform_id(db, "GetYourGuide")
    seen_pt = {}

    for _, row in df.iterrows():
        ext_id = str(int(row["gyg_tour_id"]))

        # platform_tour
        if ext_id not in seen_pt:
            pt = db.query(models.PlatformTour).filter_by(platform_id=platform_id, external_id=ext_id).first()
            if not pt:
                shorex_id = get_shorex_id(db, row["shore_name"])
                tour = db.query(models.Tour).join(models.ShoreExcursion).filter(
                    models.ShoreExcursion.shorex_id == shorex_id
                ).first() if shorex_id else None
                pt = models.PlatformTour(
                    platform_id=platform_id,
                    external_id=ext_id,
                    name=str(row["gyg_tour_name"]).strip(),
                    link=clean_str(row["link"]),
                    status="Bookable",
                    tour_id=tour.tour_id if tour else None,
                )
                db.add(pt)
                db.flush()
            seen_pt[ext_id] = pt.platform_tour_id

        # ship
        ship_name = clean_str(row["ship_name"])
        ship_id = upsert_ship(db, ship_name) if ship_name and ship_name.lower() != "combined tour" else None

        # vex_option_id — only link if the option actually exists
        vex_oid = None
        try:
            candidate = int(row["vex_option_id"])
            if db.query(models.TourOption).filter_by(option_id=candidate).first():
                vex_oid = candidate
        except (ValueError, TypeError):
            pass

        # gyg option id
        gyg_oid = None
        try:
            gyg_oid = str(int(row["gyg_option_id"]))
        except (ValueError, TypeError):
            pass

        if gyg_oid:
            exists = db.query(models.PlatformOption).filter_by(
                platform_tour_id=seen_pt[ext_id], external_option_id=gyg_oid
            ).first()
            if not exists:
                db.add(models.PlatformOption(
                    platform_tour_id=seen_pt[ext_id],
                    external_option_id=gyg_oid,
                    name=str(row["gyg_option_name"]).strip(),
                    vex_option_id=vex_oid,
                    ship_id=ship_id,
                    link=clean_str(row["link"]),
                ))
                db.flush()

    db.commit()
    print(f"    → {len(seen_pt)} GYG platform tours")


# ─────────────────────────────────────────────────────────────────────────────
# 3. VIATOR PLATFORM TOURS & OPTIONS
# ─────────────────────────────────────────────────────────────────────────────

def import_viator(db: Session, xl: pd.ExcelFile):
    print("  Importing Viator mappings...")
    df = xl.parse("ViatorVexperio")
    df.columns = ["viator_tour_name", "viator_tour_id", "viator_option_name",
                  "vex_tour_id", "vex_option_id", "vex_option_name", "shorex_name", "link", "ship_name"]
    df = df.dropna(subset=["viator_tour_id"])

    platform_id = get_platform_id(db, "Viator")
    seen_pt = {}

    for _, row in df.iterrows():
        ext_id = clean_str(row["viator_tour_id"])
        if not ext_id or ext_id == "—":
            continue

        if ext_id not in seen_pt:
            pt = db.query(models.PlatformTour).filter_by(platform_id=platform_id, external_id=ext_id).first()
            if not pt:
                vex_tid = None
                try:
                    vex_tid = int(row["vex_tour_id"])
                except (ValueError, TypeError):
                    pass
                pt = models.PlatformTour(
                    platform_id=platform_id,
                    external_id=ext_id,
                    name=str(row["viator_tour_name"]).strip(),
                    link=clean_str(row["link"]),
                    status="Active",
                    tour_id=vex_tid,
                )
                db.add(pt)
                db.flush()
            seen_pt[ext_id] = pt.platform_tour_id

        ship_name = clean_str(row["ship_name"])
        ship_id = upsert_ship(db, ship_name) if ship_name and ship_name.lower() != "combined tour" else None

        vex_oid = None
        try:
            candidate = int(row["vex_option_id"])
            if db.query(models.TourOption).filter_by(option_id=candidate).first():
                vex_oid = candidate
        except (ValueError, TypeError):
            pass

        opt_name = clean_str(row["viator_option_name"])
        if opt_name:
            exists = db.query(models.PlatformOption).filter_by(
                platform_tour_id=seen_pt[ext_id], name=opt_name
            ).first()
            if not exists:
                db.add(models.PlatformOption(
                    platform_tour_id=seen_pt[ext_id],
                    external_option_id=None,   # Viator has no numeric option IDs
                    name=opt_name,
                    vex_option_id=vex_oid,
                    ship_id=ship_id,
                    link=clean_str(row["link"]),
                ))
                db.flush()

    db.commit()
    print(f"    → {len(seen_pt)} Viator platform tours")


# ─────────────────────────────────────────────────────────────────────────────
# 4. SHIP DOCKINGS + TOUR SCHEDULES
# ─────────────────────────────────────────────────────────────────────────────

def import_schedules(db: Session, xl: pd.ExcelFile):
    print("  Importing ship dockings and tour schedules...")
    df = xl.parse("France Shared Schedule")
    df.columns = ["date", "ship", "docking_times", "port", "start", "tour", "tour_type", "duration", "status"]
    df = df.dropna(subset=["date", "ship"])

    docking_map = {}   # (ship_id, date) → docking_id
    schedule_count = 0

    for _, row in df.iterrows():
        ship_name = clean_str(row["ship"])
        if not ship_name:
            continue

        ship_id = upsert_ship(db, ship_name)
        port_obj = db.query(models.Port).filter_by(name=str(row["port"]).strip()).first()
        if not port_obj:
            continue

        dep_date = pd.Timestamp(row["date"]).date()
        dock_start, dock_end = parse_dock_times(row["docking_times"])

        key = (ship_id, dep_date)
        if key not in docking_map:
            docking = db.query(models.ShipDocking).filter_by(ship_id=ship_id, date=dep_date).first()
            if not docking:
                docking = models.ShipDocking(
                    ship_id=ship_id, port_id=port_obj.port_id,
                    date=dep_date, dock_start=dock_start, dock_end=dock_end,
                )
                db.add(docking)
                db.flush()
            docking_map[key] = docking.docking_id

        docking_id = docking_map[key]
        shorex_id = get_shorex_id(db, row["tour"])
        if not shorex_id:
            continue

        start_t = None
        try:
            start_t = pd.Timestamp(str(row["start"])).time()
        except Exception:
            pass

        tour_type = str(row["tour_type"]).strip() if clean_str(row["tour_type"]) else "Shared"
        status = str(row["status"]).strip() if clean_str(row["status"]) else "confirmed"
        duration = None
        try:
            duration = int(row["duration"])
        except (ValueError, TypeError):
            pass

        exists = db.query(models.TourSchedule).filter_by(
            docking_id=docking_id, shorex_id=shorex_id, tour_type=tour_type, start_time=start_t
        ).first()
        if not exists:
            db.add(models.TourSchedule(
                docking_id=docking_id, shorex_id=shorex_id,
                start_time=start_t, tour_type=tour_type,
                duration_hours=duration, status=status,
            ))
            schedule_count += 1

    db.commit()
    print(f"    → {len(docking_map)} dockings, {schedule_count} scheduled runs")


# ─────────────────────────────────────────────────────────────────────────────
# 5. SCHEDULE PLATFORM ENTRIES  (Vexperio / Viator / GYG)
# ─────────────────────────────────────────────────────────────────────────────

def import_schedule_entries(db: Session, xl: pd.ExcelFile):
    sheet_configs = {
        "Vexperio - schedule and pricing": {
            "platform": "Vexperio",
            "cols": ["date", "ship", "start_time", "port", "shorex_name", "tour_name",
                     "option_name", "vex_option_id", "expected_price", "entry_status",
                     "edit_status", "editor", "reviewer", "reviewed", "review", "reviewer_comments"],
            "option_col": "vex_option_id",
            "platform_col": None,
        },
        "Viator - schedule and pricing": {
            "platform": "Viator",
            "cols": ["date", "ship", "start_time", "port", "shorex_name", "viator_tour_name",
                     "viator_option_name", "viator_id", "vex_option_id", "expected_price",
                     "entry_status", "edit_status", "editor", "reviewer", "reviewed", "review", "reviewer_comments"],
            "option_col": "vex_option_id",
            "platform_col": "viator_id",
            "name_col": "viator_option_name",
        },
        "GYG - schedule and pricing": {
            "platform": "GetYourGuide",
            "cols": ["date", "ship", "start_time", "port", "shorex_name", "gyg_tour_name",
                     "gyg_option_name", "gyg_option_id", "vex_option_id", "expected_price",
                     "entry_status", "edit_status", "editor", "reviewer", "reviewed", "review", "reviewer_comments"],
            "option_col": "vex_option_id",
            "platform_col": "gyg_option_id",
            "name_col": "gyg_option_name",
        },
    }

    print("  Importing schedule platform entries...")
    total = 0

    # Idempotency: this importer appends, so clear prior entries (+ their notes)
    # before re-inserting so a re-run doesn't duplicate.
    db.query(models.Note).filter(models.Note.entity_type == "schedule_platform_entry").delete()
    db.query(models.SchedulePlatformEntry).delete()
    db.commit()

    for sheet_name, cfg in sheet_configs.items():
        df = xl.parse(sheet_name)
        if len(df.columns) < len(cfg["cols"]):
            continue
        df = df.iloc[:, :len(cfg["cols"])]
        df.columns = cfg["cols"]
        df = df.dropna(subset=["date", "ship"])
        platform_id = get_platform_id(db, cfg["platform"])

        for _, row in df.iterrows():
            ship_name = clean_str(row["ship"])
            if not ship_name:
                continue

            ship_obj = db.query(models.Ship).filter_by(name=ship_name).first()
            if not ship_obj:
                continue

            dep_date = pd.Timestamp(row["date"]).date()
            docking = db.query(models.ShipDocking).filter_by(ship_id=ship_obj.ship_id, date=dep_date).first()
            if not docking:
                continue

            shorex_id = get_shorex_id(db, row["shorex_name"])
            if not shorex_id:
                continue

            schedule = db.query(models.TourSchedule).filter_by(
                docking_id=docking.docking_id, shorex_id=shorex_id
            ).first()
            if not schedule:
                continue

            vex_oid = None
            try:
                candidate = int(row[cfg["option_col"]])
                if db.query(models.TourOption).filter_by(option_id=candidate).first():
                    vex_oid = candidate
            except (ValueError, TypeError):
                pass

            # Resolve platform_option_id for GYG / Viator entries via the
            # platform↔Vexperio linkage (GYGVexperio / ViatorVexperio set
            # PlatformOption.vex_option_id). This works for both platforms —
            # Viator has no external_option_id, so matching by ext id never
            # linked it. Vexperio entries (platform_col None) stay null.
            platform_option_id = None
            if cfg.get("platform_col") and platform_id and vex_oid is not None:
                cands = db.query(models.PlatformOption).join(models.PlatformTour).filter(
                    models.PlatformTour.platform_id == platform_id,
                    models.PlatformOption.vex_option_id == vex_oid,
                ).all()
                if len(cands) == 1:
                    platform_option_id = cands[0].platform_option_id
                elif len(cands) > 1:
                    # Tiebreak by the sheet's option name
                    sheet_name_val = clean_str(row.get(cfg.get("name_col")))
                    match = next((c for c in cands if (c.name or "").strip() == sheet_name_val), None)
                    platform_option_id = (match or cands[0]).platform_option_id

            reviewed_val = False
            try:
                reviewed_val = bool(row.get("reviewed", False))
            except Exception:
                pass

            entry = models.SchedulePlatformEntry(
                schedule_id=schedule.schedule_id,
                vex_option_id=vex_oid,
                platform_option_id=platform_option_id,
                expected_price=clean_price(row.get("expected_price")),
                entry_status=clean_str(row.get("entry_status")),
                edit_status=clean_str(row.get("edit_status")),
                editor=clean_str(row.get("editor")),
                reviewer=clean_str(row.get("reviewer")),
                reviewed=reviewed_val,
                review=clean_str(row.get("review")),
            )
            db.add(entry)
            db.flush()

            if clean_str(row.get("reviewer_comments")):
                db.add(models.Note(
                    entity_type="schedule_platform_entry",
                    entity_id=entry.entry_id,
                    note_type="review",
                    body=clean_str(row["reviewer_comments"]),
                    author=clean_str(row.get("reviewer")),
                ))
            total += 1

        db.flush()

    db.commit()
    print(f"    → {total} schedule platform entries")


# ─────────────────────────────────────────────────────────────────────────────
# 6. PRICING
# ─────────────────────────────────────────────────────────────────────────────

def import_pricing(db: Session, xl: pd.ExcelFile):
    print("  Importing pricing...")
    df = xl.parse("Pricing")
    df.columns = [
        "shorex_name", "platform_name", "platform_id_ext", "platform",
        "change_details", "price", "commission", "promo_name", "promo_pct",
        "status", "link", "change_status", "editor", "reviewer", "reviewed",
        "review", "reviewer_comments",
    ]
    df = df.dropna(subset=["shorex_name", "platform"])
    count = 0

    for _, row in df.iterrows():
        shorex_id = get_shorex_id(db, row["shorex_name"])
        platform_id = get_platform_id(db, str(row["platform"]))
        if not shorex_id or not platform_id:
            continue

        ext_id = clean_str(row["platform_id_ext"])
        pt = db.query(models.PlatformTour).filter_by(platform_id=platform_id, external_id=ext_id).first() if ext_id else None

        reviewed_val = False
        try:
            reviewed_val = bool(row.get("reviewed", False))
        except Exception:
            pass

        existing = db.query(models.Pricing).filter_by(
            shorex_id=shorex_id,
            platform_id=platform_id,
            platform_tour_id=pt.platform_tour_id if pt else None,
        ).first()

        if not existing:
            p = models.Pricing(
                shorex_id=shorex_id,
                platform_id=platform_id,
                platform_tour_id=pt.platform_tour_id if pt else None,
                price=clean_price(row["price"]),
                commission_pct=clean_price(row["commission"]),
                promo_name=clean_str(row["promo_name"]),
                promo_pct=clean_price(row["promo_pct"]),
                platform_status=clean_str(row["status"]),
                link=clean_str(row["link"]),
                change_status=clean_str(row["change_status"]),
                editor=clean_str(row["editor"]),
                reviewer=clean_str(row["reviewer"]),
                reviewed=reviewed_val,
                review=clean_str(row["review"]),
            )
            db.add(p)
            db.flush()

            # change description → note
            if clean_str(row["change_details"]):
                db.add(models.Note(
                    entity_type="pricing",
                    entity_id=p.pricing_id,
                    note_type="change",
                    body=clean_str(row["change_details"]),
                    author=clean_str(row["editor"]),
                ))

            # reviewer comment → note
            if clean_str(row["reviewer_comments"]):
                db.add(models.Note(
                    entity_type="pricing",
                    entity_id=p.pricing_id,
                    note_type="review",
                    body=clean_str(row["reviewer_comments"]),
                    author=clean_str(row["reviewer"]),
                ))
            count += 1

    db.commit()
    print(f"    → {count} pricing records")


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def run():
    print(f"\nImporting: {EXCEL_PATH}")
    xl = pd.ExcelFile(EXCEL_PATH)
    db: Session = SessionLocal()

    try:
        print("\n[1/6] Vexperio catalog")
        import_vexperio(db, xl)

        print("\n[2/6] GYG platform tours & options")
        import_gyg(db, xl)

        print("\n[3/6] Viator platform tours & options")
        import_viator(db, xl)

        print("\n[4/6] Ship dockings & tour schedules")
        import_schedules(db, xl)

        print("\n[5/6] Schedule platform entries")
        import_schedule_entries(db, xl)

        print("\n[6/6] Pricing")
        import_pricing(db, xl)

        print("\n✓ Import complete.\n")

    except Exception as e:
        db.rollback()
        print(f"\n✗ Import failed: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    run()
