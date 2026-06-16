"""Find-or-create helpers used by the Excel add-in's write endpoints.

The Excel sheet stores entities by string name (ship, port, shorex, tour name)
rather than by FK ID. These helpers let write endpoints accept either an
explicit ID or a name; if a name is provided that doesn't exist yet, a new row
is created. All helpers expect the caller to commit the surrounding transaction.
"""

from typing import Optional
from sqlalchemy.orm import Session
from api.models import Ship, Port, ShoreExcursion, ShipDocking, Tour


def resolve_ship(db: Session, ship_id: Optional[int], ship_name: Optional[str]) -> Optional[Ship]:
    """Return Ship by ID or name. Creates if name is new. Returns None if both absent."""
    if ship_id:
        return db.query(Ship).filter(Ship.ship_id == ship_id).first()
    if ship_name:
        name = ship_name.strip()
        if not name:
            return None
        existing = db.query(Ship).filter(Ship.name == name).first()
        if existing:
            return existing
        new = Ship(name=name)
        db.add(new)
        db.flush()
        return new
    return None


def resolve_port(db: Session, port_id: Optional[int], port_name: Optional[str]) -> Optional[Port]:
    if port_id:
        return db.query(Port).filter(Port.port_id == port_id).first()
    if port_name:
        name = port_name.strip()
        if not name:
            return None
        existing = db.query(Port).filter(Port.name == name).first()
        if existing:
            return existing
        new = Port(name=name)
        db.add(new)
        db.flush()
        return new
    return None


def resolve_shorex(
    db: Session,
    shorex_id: Optional[int] = None,
    shorex_name: Optional[str] = None,
    port_id: Optional[int] = None,
    port_name: Optional[str] = None,
    tour_name: Optional[str] = None,
) -> Optional[ShoreExcursion]:
    """Resolve a ShoreExcursion by ID, name, or by walking from a tour name."""
    if shorex_id:
        return db.query(ShoreExcursion).filter(ShoreExcursion.shorex_id == shorex_id).first()
    if shorex_name:
        name = shorex_name.strip()
        existing = db.query(ShoreExcursion).filter(ShoreExcursion.name == name).first()
        if existing:
            return existing
        port = resolve_port(db, port_id, port_name)
        new = ShoreExcursion(name=name, primary_port_id=port.port_id if port else None)
        db.add(new)
        db.flush()
        return new
    if tour_name:
        tour = db.query(Tour).filter(Tour.name == tour_name.strip()).first()
        if tour:
            return db.query(ShoreExcursion).filter(ShoreExcursion.shorex_id == tour.shorex_id).first()
    return None


def resolve_docking(
    db: Session,
    docking_id: Optional[int] = None,
    ship_id: Optional[int] = None,
    ship_name: Optional[str] = None,
    port_id: Optional[int] = None,
    port_name: Optional[str] = None,
    date=None,
    dock_start=None,
    dock_end=None,
) -> Optional[ShipDocking]:
    """Find docking by ID, or by (ship, date). Creates if absent and ship+port+date provided."""
    if docking_id:
        return db.query(ShipDocking).filter(ShipDocking.docking_id == docking_id).first()
    ship = resolve_ship(db, ship_id, ship_name)
    if not ship or not date:
        return None
    existing = db.query(ShipDocking).filter(
        ShipDocking.ship_id == ship.ship_id,
        ShipDocking.date == date,
    ).first()
    if existing:
        # Backfill dock times if the new write knows them and we didn't before
        if dock_start and not existing.dock_start:
            existing.dock_start = dock_start
        if dock_end and not existing.dock_end:
            existing.dock_end = dock_end
        return existing
    port = resolve_port(db, port_id, port_name)
    if not port:
        return None
    new = ShipDocking(
        ship_id=ship.ship_id,
        port_id=port.port_id,
        date=date,
        dock_start=dock_start,
        dock_end=dock_end,
    )
    db.add(new)
    db.flush()
    return new
