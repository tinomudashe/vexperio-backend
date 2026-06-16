from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import text
from typing import List
from datetime import datetime, timezone
from api.database import get_db
from api.models import Pricing, SchedulePlatformEntry, ChangeLog, Note
from api.schemas import PricingOut, ScheduleEntryOut, ReviewAction, GenericReview, ChangeLogOut, NoteOut, NoteCreate

router = APIRouter(prefix="/workflow", tags=["workflow"])


@router.get("/pending")
def pending_review(db: Session = Depends(get_db)):
    """Returns all pricing changes and schedule entries awaiting review."""
    pricing = db.query(Pricing).filter(
        Pricing.reviewed == False,
        Pricing.change_status.isnot(None)
    ).all()

    entries = db.query(SchedulePlatformEntry).filter(
        SchedulePlatformEntry.reviewed == False,
        SchedulePlatformEntry.edit_status.isnot(None)
    ).all()

    return {
        "pricing_changes": [
            {
                "pricing_id": p.pricing_id,
                "shorex_id": p.shorex_id,
                "platform_id": p.platform_id,
                "price": float(p.price) if p.price else None,
                "change_status": p.change_status,
                "editor": p.editor,
                "link": p.link,
            }
            for p in pricing
        ],
        "schedule_entries": [
            {
                "entry_id": e.entry_id,
                "schedule_id": e.schedule_id,
                "vex_option_id": e.vex_option_id,
                "platform_option_id": e.platform_option_id,
                "expected_price": float(e.expected_price) if e.expected_price else None,
                "edit_status": e.edit_status,
                "editor": e.editor,
            }
            for e in entries
        ],
        "total": len(pricing) + len(entries),
    }


@router.patch("/pricing/{pricing_id}/review", response_model=PricingOut)
def review_pricing(pricing_id: int, payload: ReviewAction, db: Session = Depends(get_db)):
    p = db.query(Pricing).filter(Pricing.pricing_id == pricing_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Pricing record not found")

    p.reviewer = payload.reviewer
    p.review = payload.review
    p.reviewed = True

    # reviewer_comments has no column on Pricing — store as a Note instead
    if payload.reviewer_comments:
        db.add(Note(
            entity_type="pricing",
            entity_id=pricing_id,
            note_type="review",
            body=payload.reviewer_comments,
            author=payload.reviewer,
        ))

    db.add(ChangeLog(
        entity_type="pricing",
        entity_id=pricing_id,
        field_name="review",
        new_value=payload.review,
        editor=payload.reviewer,
        edit_status="reviewed",
        reviewed=True,
        review=payload.review,
        reviewed_at=datetime.now(timezone.utc),
    ))

    db.commit()
    db.refresh(p)
    return p


@router.patch("/entries/{entry_id}/review", response_model=ScheduleEntryOut)
def review_entry(entry_id: int, payload: ReviewAction, db: Session = Depends(get_db)):
    entry = db.query(SchedulePlatformEntry).filter(SchedulePlatformEntry.entry_id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")

    entry.reviewer = payload.reviewer
    entry.review = payload.review
    entry.reviewed = True

    # reviewer_comments has no column on SchedulePlatformEntry — store as a Note
    if payload.reviewer_comments:
        db.add(Note(
            entity_type="schedule_platform_entry",
            entity_id=entry_id,
            note_type="review",
            body=payload.reviewer_comments,
            author=payload.reviewer,
        ))

    db.add(ChangeLog(
        entity_type="schedule_platform_entry",
        entity_id=entry_id,
        field_name="review",
        new_value=payload.review,
        editor=payload.reviewer,
        edit_status="reviewed",
        reviewed=True,
        review=payload.review,
        reviewed_at=datetime.now(timezone.utc),
    ))

    db.commit()
    db.refresh(entry)
    return entry


@router.post("/review", response_model=ChangeLogOut)
def record_review(payload: GenericReview, db: Session = Depends(get_db)):
    """Generic review recorder for any entity type. Writes a ChangeLog row and,
    for entities that carry review columns (pricing, schedule_platform_entry),
    updates those columns too."""
    log = ChangeLog(
        entity_type=payload.entity_type,
        entity_id=payload.entity_id,
        field_name=payload.field_name or "review",
        new_value=payload.review,
        editor=payload.reviewer,
        edit_status="reviewed",
        reviewer=payload.reviewer,
        reviewed=True,
        review=payload.review,
        reviewed_at=datetime.now(timezone.utc),
    )
    db.add(log)

    if payload.entity_type == "pricing":
        p = db.query(Pricing).filter(Pricing.pricing_id == payload.entity_id).first()
        if p:
            p.reviewer = payload.reviewer
            p.review = payload.review
            p.reviewed = True
    elif payload.entity_type == "schedule_platform_entry":
        e = db.query(SchedulePlatformEntry).filter(SchedulePlatformEntry.entry_id == payload.entity_id).first()
        if e:
            e.reviewer = payload.reviewer
            e.review = payload.review
            e.reviewed = True

    db.commit()
    db.refresh(log)
    return log


@router.get("/notes/{entity_type}/{entity_id}", response_model=List[NoteOut])
def get_notes(entity_type: str, entity_id: int, note_type: str = None, db: Session = Depends(get_db)):
    q = db.query(Note).filter(Note.entity_type == entity_type, Note.entity_id == entity_id)
    if note_type:
        q = q.filter(Note.note_type == note_type)
    return q.order_by(Note.created_at).all()


@router.post("/notes/{entity_type}/{entity_id}", response_model=NoteOut, status_code=201)
def add_note(entity_type: str, entity_id: int, payload: NoteCreate, db: Session = Depends(get_db)):
    note = Note(entity_type=entity_type, entity_id=entity_id, **payload.model_dump())
    db.add(note)
    db.commit()
    db.refresh(note)
    return note


@router.get("/changelog", response_model=List[ChangeLogOut])
def get_changelog(
    entity_type: str = None,
    entity_id: int = None,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    q = db.query(ChangeLog)
    if entity_type:
        q = q.filter(ChangeLog.entity_type == entity_type)
    if entity_id:
        q = q.filter(ChangeLog.entity_id == entity_id)
    return q.order_by(ChangeLog.changed_at.desc()).limit(limit).all()
