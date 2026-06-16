from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import delete
from typing import Dict, List
from api.database import get_db
from api.models import Guideline, GuidelineAttribute, Platform, Port
from api.schemas import GuidelinesSyncPayload, GuidelineAttributePayload

router = APIRouter(prefix="/guidelines", tags=["guidelines"])

@router.get("/sync", response_model=GuidelinesSyncPayload)
def get_sync(db: Session = Depends(get_db)):
    """Fetch all guidelines and format them into the UI's expected JSON shape."""
    rows = db.query(Guideline).all()
    
    general: List[GuidelineAttributePayload] = []
    platforms: Dict[str, List[GuidelineAttributePayload]] = {}
    ports: Dict[str, List[GuidelineAttributePayload]] = {}
    
    for r in rows:
        attrs = [GuidelineAttributePayload(key_name=a.key_name, value_text=a.value_text) 
                 for a in sorted(r.attributes, key=lambda x: x.order_index)]
                 
        if r.type == 'general':
            general = attrs
        elif r.type == 'platform':
            platforms[r.entity_name] = attrs
        elif r.type == 'port_excursion':
            ports[r.entity_name] = attrs
            
    return GuidelinesSyncPayload(
        general=general,
        platforms=platforms,
        ports=ports
    )


@router.post("/sync")
def post_sync(payload: GuidelinesSyncPayload, db: Session = Depends(get_db)):
    """Bulk update guidelines from the frontend."""
    # To keep it simple, we delete all existing and re-insert
    db.execute(delete(Guideline))
    
    # Try to resolve platform and port IDs for foreign keys where possible
    db_platforms = {p.name: p.platform_id for p in db.query(Platform).all()}
    db_ports = {p.name: p.port_id for p in db.query(Port).all()}
    
    # General
    if payload.general:
        g = Guideline(
            type='general',
            entity_name='General',
            updated_by=payload.updated_by
        )
        for i, attr in enumerate(payload.general):
            g.attributes.append(GuidelineAttribute(key_name=attr.key_name, value_text=attr.value_text, order_index=i))
        db.add(g)
        
    # Platforms
    for plat_name, attrs in payload.platforms.items():
        if attrs:
            g = Guideline(
                type='platform',
                entity_name=plat_name,
                platform_id=db_platforms.get(plat_name),
                updated_by=payload.updated_by
            )
            for i, attr in enumerate(attrs):
                g.attributes.append(GuidelineAttribute(key_name=attr.key_name, value_text=attr.value_text, order_index=i))
            db.add(g)
            
    # Ports/Excursions
    for port_name, attrs in payload.ports.items():
        if attrs:
            g = Guideline(
                type='port_excursion',
                entity_name=port_name,
                port_id=db_ports.get(port_name),  # Will be null if it's an excursion name rather than a port name, which is fine
                updated_by=payload.updated_by
            )
            for i, attr in enumerate(attrs):
                g.attributes.append(GuidelineAttribute(key_name=attr.key_name, value_text=attr.value_text, order_index=i))
            db.add(g)
            
    db.commit()
    return {"status": "ok", "message": "Guidelines synced"}
