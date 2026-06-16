from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, datetime, timezone
from api.database import get_db
from api.models import Departure
from api.schemas import DepartureOut, DepartureCreate, DepartureClose

router = APIRouter(prefix="/departures", tags=["departures"])


@router.get("", response_model=List[DepartureOut])
def list_departures(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    option_id: Optional[int] = None,
    status: Optional[str] = None,
    manually_closed: Optional[bool] = None,
    source: Optional[str] = None,
    db: Session = Depends(get_db)
):
    q = db.query(Departure)
    if date_from:
        q = q.filter(Departure.departure_date >= date_from)
    if date_to:
        q = q.filter(Departure.departure_date <= date_to)
    if option_id:
        q = q.filter(Departure.option_id == option_id)
    if status:
        q = q.filter(Departure.status == status)
    if manually_closed is not None:
        q = q.filter(Departure.manually_closed == manually_closed)
    if source:
        q = q.filter(Departure.source == source)
    return q.order_by(Departure.departure_date, Departure.start_time).all()


@router.get("/{departure_id}", response_model=DepartureOut)
def get_departure(departure_id: int, db: Session = Depends(get_db)):
    d = db.query(Departure).filter(Departure.departure_id == departure_id).first()
    if not d:
        raise HTTPException(status_code=404, detail="Departure not found")
    return d


@router.post("", response_model=DepartureOut, status_code=201)
def create_departure(payload: DepartureCreate, db: Session = Depends(get_db)):
    dep = Departure(**payload.model_dump())
    db.add(dep)
    db.commit()
    db.refresh(dep)
    return dep


@router.patch("/{departure_id}/close", response_model=DepartureOut)
def close_departure(departure_id: int, payload: DepartureClose, db: Session = Depends(get_db)):
    dep = db.query(Departure).filter(Departure.departure_id == departure_id).first()
    if not dep:
        raise HTTPException(status_code=404, detail="Departure not found")
    if dep.manually_closed:
        raise HTTPException(status_code=400, detail="Departure is already closed")
    dep.manually_closed = True
    dep.status = "closed"
    dep.closed_by = payload.closed_by
    dep.closed_at = datetime.now(timezone.utc)
    dep.close_reason = payload.close_reason
    db.commit()
    db.refresh(dep)
    return dep


@router.patch("/{departure_id}/reopen", response_model=DepartureOut)
def reopen_departure(departure_id: int, db: Session = Depends(get_db)):
    dep = db.query(Departure).filter(Departure.departure_id == departure_id).first()
    if not dep:
        raise HTTPException(status_code=404, detail="Departure not found")
    dep.manually_closed = False
    dep.status = "open"
    dep.closed_by = None
    dep.closed_at = None
    dep.close_reason = None
    db.commit()
    db.refresh(dep)
    return dep
