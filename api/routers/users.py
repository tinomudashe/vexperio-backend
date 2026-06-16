from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session
from typing import List
from api.database import get_db
from api.models import User
from api.schemas import UserOut, UserCreate

router = APIRouter(prefix="/users", tags=["users"])


@router.get("", response_model=List[UserOut])
def list_users(include_inactive: bool = False, db: Session = Depends(get_db)):
    q = db.query(User)
    if not include_inactive:
        q = q.filter(User.active.is_(True))
    return q.order_by(User.name).all()


@router.post("", response_model=UserOut, status_code=201)
def create_user(payload: UserCreate, db: Session = Depends(get_db)):
    name = (payload.name or "").strip()
    if not name:
        raise HTTPException(status_code=422, detail="Name is required")
    email = (payload.email or "").strip() or None

    # Email is the stable identity (a Microsoft account). Match on it first so a
    # sign-in maps to the seeded person even if the display name differs; fall
    # back to name match. Either way, reactivate and let the latest display name win.
    existing = None
    if email:
        existing = db.query(User).filter(func.lower(User.email) == email.lower()).first()
    if not existing:
        existing = db.query(User).filter(func.lower(User.name) == name.lower()).first()

    if existing:
        existing.active = True
        existing.name = name
        if email:
            existing.email = email
        db.commit()
        db.refresh(existing)
        return existing

    user = User(name=name, email=email, active=True)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.delete("/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.active = False  # soft delete — keeps historical attribution intact
    db.commit()
    return None
