from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from api.database import get_db
from api.models import Pricing, PricingHistory
from api.schemas import PricingOut, PricingUpdate, PricingCreate

router = APIRouter(prefix="/pricing", tags=["pricing"])


@router.get("", response_model=List[PricingOut])
def list_pricing(
    shorex_id: Optional[int] = None,
    platform_id: Optional[int] = None,
    change_status: Optional[str] = None,
    reviewed: Optional[bool] = None,
    vex_option_id: Optional[int] = None,
    linked: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    q = db.query(Pricing)
    if shorex_id:
        q = q.filter(Pricing.shorex_id == shorex_id)
    if platform_id:
        q = q.filter(Pricing.platform_id == platform_id)
    if change_status:
        q = q.filter(Pricing.change_status == change_status)
    if reviewed is not None:
        q = q.filter(Pricing.reviewed == reviewed)
    if vex_option_id is not None:
        q = q.filter(Pricing.vex_option_id == vex_option_id)
    if linked is not None:
        q = q.filter(Pricing.vex_option_id.isnot(None) if linked
                     else Pricing.vex_option_id.is_(None))
    return q.all()


@router.post("", response_model=PricingOut, status_code=201)
def create_pricing(payload: PricingCreate, db: Session = Depends(get_db)):
    # Check for existing pricing with this grain
    existing = db.query(Pricing).filter(
        Pricing.shorex_id == payload.shorex_id,
        Pricing.platform_id == payload.platform_id,
        Pricing.platform_tour_id == payload.platform_tour_id,
        Pricing.vex_option_id == payload.vex_option_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Pricing with this grain already exists")

    p = Pricing(**payload.model_dump(exclude_unset=True))
    db.add(p)
    db.flush()

    # snapshot creation
    snapshot = PricingHistory(
        pricing_id=p.pricing_id,
        shorex_id=p.shorex_id,
        platform_id=p.platform_id,
        platform_tour_id=p.platform_tour_id,
        price=p.price,
        commission_pct=p.commission_pct,
        promo_name=p.promo_name,
        promo_pct=p.promo_pct,
        promo_end_date=p.promo_end_date,
        platform_status=p.platform_status,
        change_status=p.change_status,
        editor=p.editor,
        change_details="Created new override"
    )
    db.add(snapshot)
    db.commit()
    db.refresh(p)
    return p


@router.get("/{pricing_id}", response_model=PricingOut)
def get_pricing(pricing_id: int, db: Session = Depends(get_db)):
    p = db.query(Pricing).filter(Pricing.pricing_id == pricing_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Pricing record not found")
    return p


@router.patch("/{pricing_id}", response_model=PricingOut)
def update_pricing(pricing_id: int, payload: PricingUpdate, db: Session = Depends(get_db)):
    p = db.query(Pricing).filter(Pricing.pricing_id == pricing_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Pricing record not found")

    # snapshot before update
    snapshot = PricingHistory(
        pricing_id=p.pricing_id,
        shorex_id=p.shorex_id,
        platform_id=p.platform_id,
        platform_tour_id=p.platform_tour_id,
        price=p.price,
        commission_pct=p.commission_pct,
        promo_name=p.promo_name,
        promo_pct=p.promo_pct,
        promo_end_date=p.promo_end_date,
        platform_status=p.platform_status,
        change_status=p.change_status,
        editor=p.editor,
        reviewer=p.reviewer,
        review=p.review,
    )
    db.add(snapshot)

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(p, field, value)
    p.reviewed = False
    p.review = None
    p.reviewer = None
    p.reviewer_comments = None

    db.commit()
    db.refresh(p)
    return p


@router.get("/{pricing_id}/history", response_model=List[dict])
def get_pricing_history(pricing_id: int, db: Session = Depends(get_db)):
    rows = db.query(PricingHistory).filter(
        PricingHistory.pricing_id == pricing_id
    ).order_by(PricingHistory.snapshotted_at.desc()).all()
    return [
        {
            "history_id": r.history_id,
            "price": float(r.price) if r.price else None,
            "commission_pct": float(r.commission_pct) if r.commission_pct is not None else None,
            "promo_name": r.promo_name,
            "promo_pct": float(r.promo_pct) if r.promo_pct is not None else None,
            "promo_end_date": r.promo_end_date,
            "platform_status": r.platform_status,
            "change_details": r.change_details,
            "change_status": r.change_status,
            "editor": r.editor,
            "review": r.review,
            "snapshotted_at": r.snapshotted_at,
        }
        for r in rows
    ]
