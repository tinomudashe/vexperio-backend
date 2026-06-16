import logging
from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from datetime import date
from api.database import get_db
from api.models import (
    ShipDocking, TourSchedule, SchedulePlatformEntry, TourOption, PlatformOption, PlatformTour,
    Ship, Port, ShoreExcursion, Tour, Platform,
)
from api.schemas import (
    DockingOut, TourScheduleOut, ScheduleEntryOut, ScheduleEntryUpdate,
    ScheduleEntryBatchCreate, ScheduleEntryEnriched, ScheduleEntryCreate,
    DockingCreate, TourScheduleCreate, TourScheduleUpdate,
)
from api.routers._resolve import resolve_docking, resolve_shorex, resolve_ship, resolve_port

router = APIRouter(prefix="/schedules", tags=["schedules"])
log = logging.getLogger(__name__)

# GYG=2, Viator=3 — platform entries auto-created when linked
_PLATFORM_ENTRY_IDS = (2, 3)


def _resolve_platform_option_id(db: Session, platform_id: int, vex_option_id: int) -> Optional[int]:
    cands = (
        db.query(PlatformOption)
        .join(PlatformTour)
        .filter(
            PlatformTour.platform_id == platform_id,
            PlatformOption.vex_option_id == vex_option_id,
        )
        .all()
    )
    if not cands:
        return None
    if len(cands) == 1:
        return cands[0].platform_option_id
    log.warning(
        "_resolve_platform_option_id: vex_option_id=%d maps to %d platform options on "
        "platform_id=%d — using platform_option_id=%d; others ignored: %s",
        vex_option_id,
        len(cands),
        platform_id,
        cands[0].platform_option_id,
        [c.platform_option_id for c in cands[1:]],
    )
    return cands[0].platform_option_id


def _create_entries_for_vex_option(
    db: Session,
    schedule_id: int,
    vex_option_id: int,
    *,
    include_platforms: bool,
    explicit_platform_ids: Optional[List[int]] = None,
) -> List[SchedulePlatformEntry]:
    opt = db.query(TourOption).filter(TourOption.option_id == vex_option_id).first()
    if not opt:
        raise HTTPException(status_code=400, detail=f"Vexperio option {vex_option_id} not found")

    created: List[SchedulePlatformEntry] = []
    expected = float(opt.base_price) if opt.base_price is not None else None

    existing_vex = db.query(SchedulePlatformEntry).filter(
        SchedulePlatformEntry.schedule_id == schedule_id,
        SchedulePlatformEntry.vex_option_id == vex_option_id,
        SchedulePlatformEntry.platform_option_id.is_(None),
    ).first()
    if not existing_vex:
        entry = SchedulePlatformEntry(
            schedule_id=schedule_id,
            vex_option_id=vex_option_id,
            platform_option_id=None,
            expected_price=expected,
        )
        db.add(entry)
        created.append(entry)

    platforms_to_add = explicit_platform_ids if explicit_platform_ids is not None else (_PLATFORM_ENTRY_IDS if include_platforms else [])

    for platform_id in platforms_to_add:
        po_id = _resolve_platform_option_id(db, platform_id, vex_option_id)
        if not po_id:
            continue
            existing_plat = db.query(SchedulePlatformEntry).filter(
                SchedulePlatformEntry.schedule_id == schedule_id,
                SchedulePlatformEntry.platform_option_id == po_id,
            ).first()
            if existing_plat:
                continue
            entry = SchedulePlatformEntry(
                schedule_id=schedule_id,
                vex_option_id=vex_option_id,
                platform_option_id=po_id,
                expected_price=expected,
            )
            db.add(entry)
            created.append(entry)

    return created


@router.get("/dockings", response_model=List[DockingOut])
def list_dockings(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    ship_id: Optional[int] = None,
    port_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    q = db.query(ShipDocking)
    if date_from:
        q = q.filter(ShipDocking.date >= date_from)
    if date_to:
        q = q.filter(ShipDocking.date <= date_to)
    if ship_id:
        q = q.filter(ShipDocking.ship_id == ship_id)
    if port_id:
        q = q.filter(ShipDocking.port_id == port_id)
    return q.order_by(ShipDocking.date).all()


@router.get("/dockings/{docking_id}", response_model=DockingOut)
def get_docking(docking_id: int, db: Session = Depends(get_db)):
    d = db.query(ShipDocking).filter(ShipDocking.docking_id == docking_id).first()
    if not d:
        raise HTTPException(status_code=404, detail="Docking not found")
    return d


@router.get("/dockings/{docking_id}/tours", response_model=List[TourScheduleOut])
def get_docking_tours(docking_id: int, db: Session = Depends(get_db)):
    return db.query(TourSchedule).options(
        joinedload(TourSchedule.platform_entries)
    ).filter(TourSchedule.docking_id == docking_id).all()


@router.get("", response_model=List[TourScheduleOut])
def list_schedules(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    shorex_id: Optional[int] = None,
    tour_type: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    q = db.query(TourSchedule).options(
        joinedload(TourSchedule.platform_entries),
        joinedload(TourSchedule.docking)
    )
    if shorex_id:
        q = q.filter(TourSchedule.shorex_id == shorex_id)
    if tour_type:
        q = q.filter(TourSchedule.tour_type == tour_type)
    if status:
        q = q.filter(TourSchedule.status == status)
    if date_from or date_to:
        q = q.join(ShipDocking)
        if date_from:
            q = q.filter(ShipDocking.date >= date_from)
        if date_to:
            q = q.filter(ShipDocking.date <= date_to)
    return q.all()


@router.get("/entries", response_model=List[ScheduleEntryEnriched])
def list_schedule_entries(
    platform_id: Optional[int] = None,
    vex_option_id: Optional[int] = None,
    shorex_id: Optional[int] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    db: Session = Depends(get_db),
):
    """Return SchedulePlatformEntry rows with all joined context.
    This is the single source of truth for schedule-level pricing in the frontend."""
    q = (
        db.query(
            SchedulePlatformEntry, TourSchedule, ShipDocking,
            Ship, Port, ShoreExcursion, TourOption, Tour,
            PlatformOption, PlatformTour, Platform,
        )
        .join(TourSchedule, TourSchedule.schedule_id == SchedulePlatformEntry.schedule_id)
        .join(ShipDocking, ShipDocking.docking_id == TourSchedule.docking_id)
        .join(Ship, Ship.ship_id == ShipDocking.ship_id)
        .join(Port, Port.port_id == ShipDocking.port_id)
        .join(ShoreExcursion, ShoreExcursion.shorex_id == TourSchedule.shorex_id)
        .outerjoin(TourOption, TourOption.option_id == SchedulePlatformEntry.vex_option_id)
        .outerjoin(Tour, Tour.tour_id == TourOption.tour_id)
        .outerjoin(PlatformOption, PlatformOption.platform_option_id == SchedulePlatformEntry.platform_option_id)
        .outerjoin(PlatformTour, PlatformTour.platform_tour_id == PlatformOption.platform_tour_id)
        .outerjoin(Platform, Platform.platform_id == PlatformTour.platform_id)
    )
    if shorex_id:
        q = q.filter(TourSchedule.shorex_id == shorex_id)
    if vex_option_id:
        q = q.filter(SchedulePlatformEntry.vex_option_id == vex_option_id)
    if platform_id:
        q = q.filter(PlatformTour.platform_id == platform_id)
    if date_from:
        q = q.filter(ShipDocking.date >= date_from)
    if date_to:
        q = q.filter(ShipDocking.date <= date_to)

    results = []
    for entry, sched, docking, ship, port, shorex, opt, tour, plat_opt, plat_tour, plat in q.all():
        results.append(ScheduleEntryEnriched(
            entry_id=entry.entry_id,
            schedule_id=entry.schedule_id,
            date=docking.date,
            ship=ship.name,
            port=port.name,
            dock_start=docking.dock_start,
            start_time=sched.start_time,
            shorex=shorex.name,
            shorex_id=shorex.shorex_id,
            tour_name=tour.name if tour else None,
            tour_id=tour.tour_id if tour else None,
            option_name=opt.name if opt else None,
            vex_option_id=entry.vex_option_id,
            platform=plat.name if plat else "Vexperio",
            platform_listing_id=plat_tour.external_id if plat_tour else None,
            platform_listing_name=plat_tour.name if plat_tour else None,
            external_option_id=plat_opt.external_option_id if plat_opt else None,
            link=(plat_opt.link if plat_opt else None) or (plat_tour.link if plat_tour else None),
            expected_price=entry.expected_price,
            entry_status=entry.entry_status,
            edit_status=entry.edit_status,
            editor=entry.editor,
            reviewer=entry.reviewer,
            reviewed=entry.reviewed,
            review=entry.review,
        ))
    return results


@router.patch("/entries/{entry_id}", response_model=ScheduleEntryOut)
def update_schedule_entry(
    entry_id: int,
    payload: ScheduleEntryUpdate,
    db: Session = Depends(get_db),
):
    """Update a SchedulePlatformEntry by entry_id (no schedule_id needed)."""
    entry = db.query(SchedulePlatformEntry).filter(
        SchedulePlatformEntry.entry_id == entry_id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/{schedule_id}", response_model=TourScheduleOut)
def get_schedule(schedule_id: int, db: Session = Depends(get_db)):
    s = db.query(TourSchedule).options(
        joinedload(TourSchedule.platform_entries)
    ).filter(TourSchedule.schedule_id == schedule_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Schedule not found")
    return s


@router.post("/{schedule_id}/entries", response_model=ScheduleEntryOut, status_code=201)
def create_single_entry(schedule_id: int, payload: ScheduleEntryCreate, db: Session = Depends(get_db)):
    schedule = db.query(TourSchedule).filter(TourSchedule.schedule_id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Schedule not found")

    # Check if exists
    existing = db.query(SchedulePlatformEntry).filter(
        SchedulePlatformEntry.schedule_id == schedule_id,
        SchedulePlatformEntry.platform_option_id == payload.platform_option_id,
        SchedulePlatformEntry.vex_option_id == payload.vex_option_id
    ).first()
    if existing:
        return existing

    entry = SchedulePlatformEntry(
        schedule_id=schedule_id,
        vex_option_id=payload.vex_option_id,
        platform_option_id=payload.platform_option_id,
        expected_price=payload.expected_price
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.patch("/{schedule_id}/entries/{entry_id}", response_model=ScheduleEntryOut)
def update_entry(schedule_id: int, entry_id: int, payload: ScheduleEntryUpdate, db: Session = Depends(get_db)):
    entry = db.query(SchedulePlatformEntry).filter(
        SchedulePlatformEntry.entry_id == entry_id,
        SchedulePlatformEntry.schedule_id == schedule_id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return entry


@router.post("/{schedule_id}/entries/batch", response_model=List[ScheduleEntryOut], status_code=201)
def create_entries_batch(
    schedule_id: int,
    payload: ScheduleEntryBatchCreate,
    db: Session = Depends(get_db),
):
    schedule = db.query(TourSchedule).filter(TourSchedule.schedule_id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Schedule not found")
    if not payload.vex_option_ids:
        raise HTTPException(status_code=400, detail="vex_option_ids required")

    created: List[SchedulePlatformEntry] = []
    for vex_option_id in payload.vex_option_ids:
        explicit_platform_ids = None
        if payload.platform_map is not None:
            if vex_option_id in payload.platform_map:
                explicit_platform_ids = payload.platform_map[vex_option_id]
            elif str(vex_option_id) in payload.platform_map:
                explicit_platform_ids = payload.platform_map[str(vex_option_id)]

        created.extend(
            _create_entries_for_vex_option(
                db,
                schedule_id,
                vex_option_id,
                include_platforms=payload.include_platforms,
                explicit_platform_ids=explicit_platform_ids,
            )
        )
    db.commit()
    for entry in created:
        db.refresh(entry)
    return created


@router.delete("/{schedule_id}/entries/{entry_id}", status_code=204)
def delete_entry(schedule_id: int, entry_id: int, db: Session = Depends(get_db)):
    entry = db.query(SchedulePlatformEntry).filter(
        SchedulePlatformEntry.entry_id == entry_id,
        SchedulePlatformEntry.schedule_id == schedule_id,
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    db.delete(entry)
    db.commit()
    return Response(status_code=204)


@router.delete("/{schedule_id}/entries/by-vex-option/{vex_option_id}", status_code=204)
def delete_entries_for_vex_option(
    schedule_id: int,
    vex_option_id: int,
    db: Session = Depends(get_db),
):
    schedule = db.query(TourSchedule).filter(TourSchedule.schedule_id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Schedule not found")
    db.query(SchedulePlatformEntry).filter(
        SchedulePlatformEntry.schedule_id == schedule_id,
        SchedulePlatformEntry.vex_option_id == vex_option_id,
    ).delete()
    db.commit()
    return Response(status_code=204)


@router.patch("/{schedule_id}/cancel", response_model=TourScheduleOut)
def cancel_schedule(schedule_id: int, db: Session = Depends(get_db)):
    s = db.query(TourSchedule).filter(TourSchedule.schedule_id == schedule_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Schedule not found")
    s.status = "Cancelled"
    db.commit()
    db.refresh(s)
    return s


# ── Docking + schedule CRUD (mirror of Excel writes) ────────────────────────

@router.post("/dockings", response_model=DockingOut, status_code=201)
def create_docking(payload: DockingCreate, db: Session = Depends(get_db)):
    """Create a docking. Upserts on (ship_id, date)."""
    ship = resolve_ship(db, payload.ship_id, payload.ship_name)
    if not ship:
        raise HTTPException(status_code=400, detail="Must supply ship_id or ship_name")
    port = resolve_port(db, payload.port_id, payload.port_name)
    if not port:
        raise HTTPException(status_code=400, detail="Must supply port_id or port_name")

    existing = db.query(ShipDocking).filter(
        ShipDocking.ship_id == ship.ship_id,
        ShipDocking.date == payload.date,
    ).first()
    if existing:
        if payload.dock_start is not None: existing.dock_start = payload.dock_start
        if payload.dock_end is not None:   existing.dock_end   = payload.dock_end
        existing.port_id = port.port_id
        db.commit()
        db.refresh(existing)
        return existing

    docking = ShipDocking(
        ship_id=ship.ship_id,
        port_id=port.port_id,
        date=payload.date,
        dock_start=payload.dock_start,
        dock_end=payload.dock_end,
    )
    db.add(docking)
    db.commit()
    db.refresh(docking)
    return docking


@router.post("", response_model=TourScheduleOut, status_code=201)
def create_schedule(payload: TourScheduleCreate, db: Session = Depends(get_db)):
    """Create a TourSchedule. Resolves/creates the docking and shorex on the fly so
    the Excel add-in can mirror with just strings."""
    # 1. Resolve or create the docking
    docking = resolve_docking(
        db,
        docking_id=payload.docking_id,
        ship_name=payload.ship_name,
        port_name=payload.port_name,
        date=payload.date,
        dock_start=payload.dock_start,
        dock_end=payload.dock_end,
    )
    if not docking:
        raise HTTPException(
            status_code=400,
            detail="Could not resolve docking. Provide docking_id, or ship_name+port_name+date."
        )

    # 2. Resolve shorex
    shorex = resolve_shorex(
        db,
        shorex_id=payload.shorex_id,
        shorex_name=payload.shorex_name,
        tour_name=payload.tour_name,
    )
    if not shorex:
        raise HTTPException(
            status_code=400,
            detail="Could not resolve shorex. Provide shorex_id, shorex_name, or tour_name."
        )

    # 3. Upsert on (docking_id, shorex_id, tour_type, start_time)
    existing = db.query(TourSchedule).filter(
        TourSchedule.docking_id == docking.docking_id,
        TourSchedule.shorex_id == shorex.shorex_id,
        TourSchedule.tour_type == payload.tour_type,
        TourSchedule.start_time == payload.start_time,
    ).first()
    if existing:
        existing.duration_hours = payload.duration_hours
        existing.status = payload.status
        db.commit()
        db.refresh(existing)
        return existing

    schedule = TourSchedule(
        docking_id=docking.docking_id,
        shorex_id=shorex.shorex_id,
        start_time=payload.start_time,
        tour_type=payload.tour_type,
        duration_hours=payload.duration_hours,
        status=payload.status,
    )
    db.add(schedule)
    db.commit()
    db.refresh(schedule)
    return schedule


@router.patch("/{schedule_id}", response_model=TourScheduleOut)
def update_schedule(schedule_id: int, payload: TourScheduleUpdate, db: Session = Depends(get_db)):
    s = db.query(TourSchedule).filter(TourSchedule.schedule_id == schedule_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Schedule not found")

    # Re-link docking if ship/date changed
    if payload.docking_id or payload.ship_name or payload.date:
        docking = resolve_docking(
            db,
            docking_id=payload.docking_id,
            ship_name=payload.ship_name,
            port_name=payload.port_name,
            date=payload.date,
            dock_start=payload.dock_start,
            dock_end=payload.dock_end,
        )
        if docking:
            s.docking_id = docking.docking_id

    if payload.shorex_id or payload.shorex_name or payload.tour_name:
        sx = resolve_shorex(
            db,
            shorex_id=payload.shorex_id,
            shorex_name=payload.shorex_name,
            tour_name=payload.tour_name,
        )
        if sx:
            s.shorex_id = sx.shorex_id

    if payload.start_time is not None:     s.start_time = payload.start_time
    if payload.tour_type is not None:       s.tour_type = payload.tour_type
    if payload.duration_hours is not None:  s.duration_hours = payload.duration_hours
    if payload.status is not None:          s.status = payload.status

    db.commit()
    db.refresh(s)
    return s


@router.delete("/{schedule_id}", status_code=204)
def delete_schedule(schedule_id: int, db: Session = Depends(get_db)):
    """Hard-delete a schedule and its platform entries."""
    s = db.query(TourSchedule).filter(TourSchedule.schedule_id == schedule_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Schedule not found")
    db.query(SchedulePlatformEntry).filter(SchedulePlatformEntry.schedule_id == schedule_id).delete()
    db.delete(s)
    db.commit()
    return Response(status_code=204)
