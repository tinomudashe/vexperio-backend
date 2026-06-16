from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from api.database import get_db
from api.models import Tour, TourOption, ShoreExcursion, OptionAvailability, OptionStartTime, OptionBlockedPeriod
from api.schemas import (
    TourOut, TourWithOptions, TourOptionOut, AvailabilityOut, AvailabilityIn,
    TourCreate, TourUpdate, TourOptionCreate, TourOptionUpdate,
)
from api.routers._resolve import resolve_shorex, resolve_ship

router = APIRouter(prefix="/tours", tags=["tours"])


@router.get("", response_model=List[TourOut])
def list_tours(shorex_id: Optional[int] = None, status: Optional[str] = None, db: Session = Depends(get_db)):
    q = db.query(Tour)
    if shorex_id:
        q = q.filter(Tour.shorex_id == shorex_id)
    if status:
        q = q.filter(Tour.status == status)
    return q.all()


@router.get("/{tour_id}", response_model=TourWithOptions)
def get_tour(tour_id: int, db: Session = Depends(get_db)):
    tour = db.query(Tour).options(joinedload(Tour.options)).filter(Tour.tour_id == tour_id).first()
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    return tour


@router.get("/{tour_id}/options", response_model=List[TourOptionOut])
def list_options(tour_id: int, is_private: Optional[bool] = None, db: Session = Depends(get_db)):
    q = db.query(TourOption).filter(TourOption.tour_id == tour_id)
    if is_private is not None:
        q = q.filter(TourOption.is_private == is_private)
    return q.all()


@router.get("/{tour_id}/options/{option_id}", response_model=TourOptionOut)
def get_option(tour_id: int, option_id: int, db: Session = Depends(get_db)):
    opt = db.query(TourOption).filter(TourOption.tour_id == tour_id, TourOption.option_id == option_id).first()
    if not opt:
        raise HTTPException(status_code=404, detail="Option not found")
    return opt


@router.get("/{tour_id}/options/{option_id}/availability", response_model=List[AvailabilityOut])
def get_availability(tour_id: int, option_id: int, db: Session = Depends(get_db)):
    opt = db.query(TourOption).filter(TourOption.tour_id == tour_id, TourOption.option_id == option_id).first()
    if not opt:
        raise HTTPException(status_code=404, detail="Option not found")
    return db.query(OptionAvailability).options(
        joinedload(OptionAvailability.start_times),
        joinedload(OptionAvailability.blocked_periods)
    ).filter(OptionAvailability.option_id == option_id).all()


@router.post("/{tour_id}/options/{option_id}/availability", response_model=AvailabilityOut)
def set_availability(tour_id: int, option_id: int, payload: AvailabilityIn, db: Session = Depends(get_db)):
    opt = db.query(TourOption).filter(TourOption.tour_id == tour_id, TourOption.option_id == option_id).first()
    if not opt:
        raise HTTPException(status_code=404, detail="Option not found")

    avail = OptionAvailability(
        option_id=option_id,
        schedule_type=payload.schedule_type,
        valid_from=payload.valid_from,
        valid_to=payload.valid_to,
        mon=payload.mon, tue=payload.tue, wed=payload.wed,
        thu=payload.thu, fri=payload.fri, sat=payload.sat, sun=payload.sun,
        cms_status=payload.cms_status,
    )
    db.add(avail)
    db.flush()

    for t in payload.start_times:
        db.add(OptionStartTime(availability_id=avail.availability_id, start_time=t))
    for bp in payload.blocked_periods:
        db.add(OptionBlockedPeriod(
            availability_id=avail.availability_id,
            date_from=bp.date_from, date_to=bp.date_to, reason=bp.reason
        ))

    db.commit()
    db.refresh(avail)
    return avail


# ── Tour CRUD (mirror of Excel writes) ──────────────────────────────────────

@router.post("", response_model=TourOut, status_code=201)
def create_tour(payload: TourCreate, db: Session = Depends(get_db)):
    """Create a tour. tour_id is supplied by the caller (Excel-assigned Vexperio ID).
    If the tour already exists, treat as upsert and update fields instead."""
    shorex = resolve_shorex(
        db, payload.shorex_id, payload.shorex_name,
        port_name=payload.port_name,
    )
    if not shorex:
        raise HTTPException(status_code=400, detail="Must supply shorex_id or shorex_name")

    existing = db.query(Tour).filter(Tour.tour_id == payload.tour_id).first()
    if existing:
        existing.shorex_id = shorex.shorex_id
        existing.name = payload.name
        existing.status = payload.status
        existing.link = payload.link
        db.commit()
        db.refresh(existing)
        return existing

    tour = Tour(
        tour_id=payload.tour_id,
        shorex_id=shorex.shorex_id,
        name=payload.name,
        status=payload.status,
        link=payload.link,
    )
    db.add(tour)
    db.commit()
    db.refresh(tour)
    return tour


@router.patch("/{tour_id}", response_model=TourOut)
def update_tour(tour_id: int, payload: TourUpdate, db: Session = Depends(get_db)):
    tour = db.query(Tour).filter(Tour.tour_id == tour_id).first()
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    if payload.shorex_id or payload.shorex_name:
        sx = resolve_shorex(db, payload.shorex_id, payload.shorex_name)
        if sx:
            tour.shorex_id = sx.shorex_id
    if payload.name is not None:   tour.name = payload.name
    if payload.status is not None: tour.status = payload.status
    if payload.link is not None:   tour.link = payload.link
    db.commit()
    db.refresh(tour)
    return tour


@router.delete("/{tour_id}", status_code=204)
def delete_tour(tour_id: int, cascade_options: bool = False, db: Session = Depends(get_db)):
    """Delete a tour. By default refuses if it still has options; cascade_options=true
    deletes the options first."""
    tour = db.query(Tour).filter(Tour.tour_id == tour_id).first()
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    opts = db.query(TourOption).filter(TourOption.tour_id == tour_id).all()
    if opts and not cascade_options:
        raise HTTPException(
            status_code=409,
            detail=f"Tour has {len(opts)} option(s). Pass cascade_options=true to delete them."
        )
    for o in opts:
        db.delete(o)
    db.delete(tour)
    db.commit()
    return Response(status_code=204)


# ── Option CRUD ─────────────────────────────────────────────────────────────

@router.post("/{tour_id}/options", response_model=TourOptionOut, status_code=201)
def create_option(tour_id: int, payload: TourOptionCreate, db: Session = Depends(get_db)):
    tour = db.query(Tour).filter(Tour.tour_id == tour_id).first()
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    ship = resolve_ship(db, payload.ship_id, payload.ship_name)

    if payload.option_id:
        existing = db.query(TourOption).filter(TourOption.option_id == payload.option_id).first()
        if existing:
            existing.tour_id = tour_id
            existing.name = payload.name
            existing.is_private = payload.is_private
            existing.ship_id = ship.ship_id if ship else None
            existing.base_price = payload.base_price
            existing.link = payload.link
            db.commit()
            db.refresh(existing)
            return existing

    opt = TourOption(
        **({"option_id": payload.option_id} if payload.option_id else {}),
        tour_id=tour_id,
        name=payload.name,
        is_private=payload.is_private,
        ship_id=ship.ship_id if ship else None,
        base_price=payload.base_price,
        link=payload.link,
    )
    db.add(opt)
    db.commit()
    db.refresh(opt)
    return opt


@router.patch("/{tour_id}/options/{option_id}", response_model=TourOptionOut)
def update_option(tour_id: int, option_id: int, payload: TourOptionUpdate, db: Session = Depends(get_db)):
    opt = db.query(TourOption).filter(TourOption.tour_id == tour_id, TourOption.option_id == option_id).first()
    if not opt:
        raise HTTPException(status_code=404, detail="Option not found")
    if payload.name is not None:       opt.name = payload.name
    if payload.is_private is not None: opt.is_private = payload.is_private
    if payload.base_price is not None: opt.base_price = payload.base_price
    if payload.link is not None:       opt.link = payload.link
    if payload.ship_id or payload.ship_name:
        ship = resolve_ship(db, payload.ship_id, payload.ship_name)
        if ship:
            opt.ship_id = ship.ship_id
    db.commit()
    db.refresh(opt)
    return opt


@router.delete("/{tour_id}/options/{option_id}", status_code=204)
def delete_option(tour_id: int, option_id: int, db: Session = Depends(get_db)):
    opt = db.query(TourOption).filter(TourOption.tour_id == tour_id, TourOption.option_id == option_id).first()
    if not opt:
        raise HTTPException(status_code=404, detail="Option not found")
    db.delete(opt)
    db.commit()
    return Response(status_code=204)
