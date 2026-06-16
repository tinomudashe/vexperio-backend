from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from api.database import get_db
from api.models import Ship, Port, ShoreExcursion, Platform

router = APIRouter(prefix="/reference", tags=["reference"])


@router.get("")
def get_reference(db: Session = Depends(get_db)):
    """Returns ships, ports, shore excursions and platforms in one round-trip.
    Used by the Excel add-in to build lookup maps before fetching entity data."""
    ships = db.query(Ship).order_by(Ship.name).all()
    ports = db.query(Port).order_by(Port.name).all()
    shorex = db.query(ShoreExcursion).order_by(ShoreExcursion.shorex_id).all()
    platforms = db.query(Platform).order_by(Platform.platform_id).all()

    return {
        "ships": [{"ship_id": s.ship_id, "name": s.name} for s in ships],
        "ports": [{"port_id": p.port_id, "name": p.name} for p in ports],
        "shorex": [
            {
                "shorex_id": s.shorex_id,
                "name": s.name,
                "port_id": s.primary_port_id,
            }
            for s in shorex
        ],
        "platforms": [
            {
                "platform_id": p.platform_id,
                "name": p.name,
                "applies_commission": p.applies_commission,
                "commission_pct": float(p.commission_pct) if p.commission_pct else None,
            }
            for p in platforms
        ],
    }
