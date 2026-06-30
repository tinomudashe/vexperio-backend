from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from api.database import get_db
from api.models import Platform, PlatformTour, PlatformOption, PlatformCommission, Discount, SchedulePlatformEntry
from api.schemas import (
    PlatformOut, PlatformCreate, PlatformPatch, PlatformTourOut, PlatformOptionOut, PlatformOptionCreate, PlatformOptionPatch,
    PlatformTourCreate, PlatformTourUpdate,
    CommissionOut, CommissionCreate, DiscountOut, DiscountCreate, DiscountUpdate,
)

router = APIRouter(tags=["platforms"])


# ── Platforms ───────────────────────────────────────────────────────────────

@router.get("/platforms", response_model=List[PlatformOut])
def list_platforms(db: Session = Depends(get_db)):
    return db.query(Platform).all()


@router.post("/platforms", response_model=PlatformOut, status_code=201)
def create_platform(payload: PlatformCreate, db: Session = Depends(get_db)):
    existing = db.query(Platform).filter(Platform.name == payload.name).first()
    if existing:
        raise HTTPException(status_code=409, detail="Platform with this name already exists")
    
    p = Platform(**payload.model_dump())
    db.add(p)
    db.commit()
    db.refresh(p)
    return p


@router.patch("/platforms/{platform_id}", response_model=PlatformOut)
def update_platform(platform_id: int, payload: PlatformPatch, db: Session = Depends(get_db)):
    p = db.query(Platform).filter(Platform.platform_id == platform_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Platform not found")
    
    updates = payload.model_dump(exclude_unset=True)
    if "name" in updates and updates["name"] != p.name:
        clash = db.query(Platform).filter(Platform.name == updates["name"], Platform.platform_id != platform_id).first()
        if clash:
            raise HTTPException(status_code=409, detail="Platform with this name already exists")

    for field, val in updates.items():
        setattr(p, field, val)
    
    db.commit()
    db.refresh(p)
    return p


# ── Platform Tours ──────────────────────────────────────────────────────────

@router.get("/platforms/{platform_id}/tours", response_model=List[PlatformTourOut])
def list_platform_tours(platform_id: int, tour_id: Optional[int] = None, db: Session = Depends(get_db)):
    q = db.query(PlatformTour).options(joinedload(PlatformTour.options)).filter(PlatformTour.platform_id == platform_id)
    if tour_id:
        q = q.filter(PlatformTour.tour_id == tour_id)
    return q.all()


@router.get("/platform-tours/{platform_tour_id}", response_model=PlatformTourOut)
def get_platform_tour(platform_tour_id: int, db: Session = Depends(get_db)):
    pt = db.query(PlatformTour).options(joinedload(PlatformTour.options)).filter(
        PlatformTour.platform_tour_id == platform_tour_id
    ).first()
    if not pt:
        raise HTTPException(status_code=404, detail="Platform tour not found")
    return pt


@router.get("/platform-tours/{platform_tour_id}/options", response_model=List[PlatformOptionOut])
def list_platform_options(platform_tour_id: int, db: Session = Depends(get_db)):
    return db.query(PlatformOption).filter(PlatformOption.platform_tour_id == platform_tour_id).all()


@router.post("/platform-tours/{platform_tour_id}/options", response_model=PlatformOptionOut, status_code=201)
def create_platform_option(platform_tour_id: int, payload: PlatformOptionCreate, db: Session = Depends(get_db)):
    pt = db.query(PlatformTour).filter(PlatformTour.platform_tour_id == platform_tour_id).first()
    if not pt:
        raise HTTPException(status_code=404, detail="Platform tour not found")

    if payload.external_option_id:
        existing = db.query(PlatformOption).filter(
            PlatformOption.platform_tour_id == platform_tour_id,
            PlatformOption.external_option_id == payload.external_option_id,
        ).first()
        if existing:
            raise HTTPException(
                status_code=409,
                detail=f"Platform option with external ID {payload.external_option_id} already exists on this listing.",
            )

    opt = PlatformOption(
        platform_tour_id=platform_tour_id,
        external_option_id=payload.external_option_id,
        name=payload.name.strip(),
        vex_option_id=payload.vex_option_id,
        ship_id=payload.ship_id,
        link=payload.link,
    )
    db.add(opt)
    db.commit()
    db.refresh(opt)
    return opt


@router.patch("/platform-options/{platform_option_id}", response_model=PlatformOptionOut)
def update_platform_option(platform_option_id: int, payload: PlatformOptionPatch, db: Session = Depends(get_db)):
    opt = db.query(PlatformOption).filter(PlatformOption.platform_option_id == platform_option_id).first()
    if not opt:
        raise HTTPException(status_code=404, detail="Platform option not found")
    updates = payload.model_dump(exclude_unset=True)
    if "external_option_id" in updates and updates["external_option_id"]:
        clash = db.query(PlatformOption).filter(
            PlatformOption.platform_tour_id == opt.platform_tour_id,
            PlatformOption.external_option_id == updates["external_option_id"],
            PlatformOption.platform_option_id != platform_option_id,
        ).first()
        if clash:
            raise HTTPException(status_code=409, detail="Another option on this listing already uses that external ID.")
    for field, val in updates.items():
        if field == "name" and val is not None:
            val = val.strip()
        setattr(opt, field, val)
    db.commit()
    db.refresh(opt)
    return opt


@router.delete("/platform-options/{platform_option_id}", status_code=204)
def delete_platform_option(platform_option_id: int, db: Session = Depends(get_db)):
    opt = db.query(PlatformOption).filter(PlatformOption.platform_option_id == platform_option_id).first()
    if not opt:
        raise HTTPException(status_code=404, detail="Platform option not found")
    refs = db.query(SchedulePlatformEntry).filter(
        SchedulePlatformEntry.platform_option_id == platform_option_id
    ).count()
    if refs:
        raise HTTPException(
            status_code=409,
            detail=f"Platform option is referenced by {refs} schedule entr{'y' if refs == 1 else 'ies'} — detach first.",
        )
    db.delete(opt)
    db.commit()
    return Response(status_code=204)


# ── Platform Tour CRUD (mirror of Excel writes) ─────────────────────────────

@router.post("/platforms/{platform_id}/tours", response_model=PlatformTourOut, status_code=201)
def create_platform_tour(platform_id: int, payload: PlatformTourCreate, db: Session = Depends(get_db)):
    """Create a platform listing. Upserts by (platform_id, external_id) — if a listing
    with the same external_id already exists on this platform, its fields are updated."""
    platform = db.query(Platform).filter(Platform.platform_id == platform_id).first()
    if not platform:
        raise HTTPException(status_code=404, detail="Platform not found")

    existing = db.query(PlatformTour).filter(
        PlatformTour.platform_id == platform_id,
        PlatformTour.external_id == payload.external_id,
    ).first()
    if existing:
        existing.name = payload.name
        existing.link = payload.link
        existing.status = payload.status
        if payload.tour_id is not None:
            existing.tour_id = payload.tour_id
        db.commit()
        db.refresh(existing)
        return existing

    pt = PlatformTour(
        platform_id=platform_id,
        external_id=payload.external_id,
        name=payload.name,
        link=payload.link,
        status=payload.status,
        tour_id=payload.tour_id,
    )
    db.add(pt)
    db.commit()
    db.refresh(pt)
    return pt


@router.patch("/platform-tours/{platform_tour_id}", response_model=PlatformTourOut)
def update_platform_tour(platform_tour_id: int, payload: PlatformTourUpdate, db: Session = Depends(get_db)):
    pt = db.query(PlatformTour).filter(PlatformTour.platform_tour_id == platform_tour_id).first()
    if not pt:
        raise HTTPException(status_code=404, detail="Platform tour not found")
    if payload.external_id is not None: pt.external_id = payload.external_id
    if payload.name is not None:         pt.name = payload.name
    if payload.link is not None:         pt.link = payload.link
    if payload.status is not None:       pt.status = payload.status
    if payload.tour_id is not None:      pt.tour_id = payload.tour_id
    db.commit()
    db.refresh(pt)
    return pt


@router.delete("/platform-tours/{platform_tour_id}", status_code=204)
def delete_platform_tour(platform_tour_id: int, db: Session = Depends(get_db)):
    """Delete a platform listing. Refuses if it still has linked platform options."""
    pt = db.query(PlatformTour).filter(PlatformTour.platform_tour_id == platform_tour_id).first()
    if not pt:
        raise HTTPException(status_code=404, detail="Platform tour not found")
    opts = db.query(PlatformOption).filter(PlatformOption.platform_tour_id == platform_tour_id).count()
    if opts:
        raise HTTPException(
            status_code=409,
            detail=f"Listing has {opts} platform option(s) — detach them first.",
        )
    db.delete(pt)
    db.commit()
    return Response(status_code=204)


# Convenience: find a platform-tour by (platform, external_id) — used by the
# Excel add-in to map Excel mappings to API IDs.
@router.get("/platforms/{platform_id}/tours/by-external/{external_id}", response_model=PlatformTourOut)
def get_platform_tour_by_external(platform_id: int, external_id: str, db: Session = Depends(get_db)):
    pt = db.query(PlatformTour).options(joinedload(PlatformTour.options)).filter(
        PlatformTour.platform_id == platform_id,
        PlatformTour.external_id == external_id,
    ).first()
    if not pt:
        raise HTTPException(status_code=404, detail="Platform tour not found")
    return pt


# ── Commissions ─────────────────────────────────────────────────────────────

@router.get("/commissions", response_model=List[CommissionOut])
def list_commissions(platform_id: Optional[int] = None, db: Session = Depends(get_db)):
    q = db.query(PlatformCommission)
    if platform_id:
        q = q.filter(PlatformCommission.platform_id == platform_id)
    return q.all()


@router.post("/commissions", response_model=CommissionOut)
def create_commission(payload: CommissionCreate, db: Session = Depends(get_db)):
    platform = db.query(Platform).filter(Platform.platform_id == payload.platform_id).first()
    if not platform:
        raise HTTPException(status_code=404, detail="Platform not found")
    if not platform.applies_commission:
        raise HTTPException(status_code=400, detail="Vexperio is in-house and does not have a commission")
    c = PlatformCommission(**payload.model_dump())
    db.add(c)
    db.commit()
    db.refresh(c)
    return c


@router.delete("/commissions/{commission_id}", status_code=204)
def delete_commission(commission_id: int, db: Session = Depends(get_db)):
    c = db.query(PlatformCommission).filter(PlatformCommission.commission_id == commission_id).first()
    if not c:
        raise HTTPException(status_code=404, detail="Commission not found")
    db.delete(c)
    db.commit()


# ── Discounts ───────────────────────────────────────────────────────────────

@router.get("/discounts", response_model=List[DiscountOut])
def list_discounts(status: Optional[str] = "active", platform_id: Optional[int] = None, platform_option_id: Optional[int] = None, db: Session = Depends(get_db)):
    q = db.query(Discount)
    if status and status != "all":
        q = q.filter(Discount.status == status)
    if platform_id:
        q = q.filter(Discount.platform_id == platform_id)
    if platform_option_id:
        q = q.filter(Discount.platform_option_id == platform_option_id)
    return q.all()


@router.post("/discounts", response_model=DiscountOut)
def create_discount(payload: DiscountCreate, db: Session = Depends(get_db)):
    d = Discount(**payload.model_dump())
    db.add(d)
    db.commit()
    db.refresh(d)
    return d


@router.patch("/discounts/{discount_id}", response_model=DiscountOut)
def update_discount(discount_id: int, payload: DiscountUpdate, db: Session = Depends(get_db)):
    d = db.query(Discount).filter(Discount.discount_id == discount_id).first()
    if not d:
        raise HTTPException(status_code=404, detail="Discount not found")
    updates = payload.model_dump(exclude_unset=True)
    for field, val in updates.items():
        setattr(d, field, val)
    db.commit()
    db.refresh(d)
    return d


@router.patch("/discounts/{discount_id}/deactivate", response_model=DiscountOut)
def deactivate_discount(discount_id: int, db: Session = Depends(get_db)):
    d = db.query(Discount).filter(Discount.discount_id == discount_id).first()
    if not d:
        raise HTTPException(status_code=404, detail="Discount not found")
    d.status = "inactive"
    db.commit()
    db.refresh(d)
    return d
