"""Centralized audit logging.

A pair of SQLAlchemy session listeners write a `change_log` row for every
create / update / delete of a tracked entity, attributed to the current editor
(set from the `X-Editor` request header by a middleware in main.py).

Two phases are required:
  * before_flush — attribute change-history (old/new values) is only readable
    here, and PKs for updates/deletes already exist.
  * after_flush  — autoincrement PKs for freshly-inserted rows are populated
    here, so insert rows can finally be written.

Bulk sheet-sync disables logging via the `audit_enabled` contextvar so it does
not flood the log with thousands of rows.
"""

import contextvars
from datetime import date, time, datetime
from decimal import Decimal

from sqlalchemy import event, inspect

from api.database import SessionLocal
from api.models import (
    ChangeLog, Tour, TourOption, PlatformTour, PlatformOption,
    TourSchedule, SchedulePlatformEntry, Pricing,
)

# Set per-request from the X-Editor header (see main.py middleware).
current_editor = contextvars.ContextVar("current_editor", default=None)
# Bulk operations (sheet sync) flip this off to avoid flooding the log.
audit_enabled = contextvars.ContextVar("audit_enabled", default=True)

# model class -> (entity_type, primary-key attribute)
TRACKED = {
    Tour:                  ("tour", "tour_id"),
    TourOption:            ("tour_option", "option_id"),
    PlatformTour:          ("platform_tour", "platform_tour_id"),
    PlatformOption:        ("platform_option", "platform_option_id"),
    TourSchedule:          ("schedule", "schedule_id"),
    SchedulePlatformEntry: ("schedule_platform_entry", "entry_id"),
    Pricing:               ("pricing", "pricing_id"),
}

# Review-workflow + bookkeeping columns: logged by the review endpoints or noise.
SKIP_FIELDS = {
    "created_at", "updated_at", "reviewed", "review", "reviewer",
    "reviewer_comments", "reviewed_at", "editor",
}


def _s(v):
    if v is None:
        return None
    if isinstance(v, (date, time, datetime)):
        return v.isoformat()
    if isinstance(v, Decimal):
        return str(v)
    return str(v)


@event.listens_for(SessionLocal, "before_flush")
def _audit_before_flush(session, flush_context, instances):
    if not audit_enabled.get():
        return

    pending = session.info.setdefault("_audit", [])

    for obj in session.new:
        meta = TRACKED.get(type(obj))
        if meta:
            etype, pk_attr = meta
            pending.append(("insert", obj, etype, pk_attr, None))

    for obj in session.dirty:
        meta = TRACKED.get(type(obj))
        if not meta or not session.is_modified(obj, include_collections=False):
            continue
        etype, pk_attr = meta
        state = inspect(obj)
        for attr in state.attrs:
            if attr.key in SKIP_FIELDS:
                continue
            hist = attr.history
            if not hist.has_changes():
                continue
            old = hist.deleted[0] if hist.deleted else None
            new = hist.added[0] if hist.added else None
            if old == new:
                continue
            pending.append(("update", obj, etype, pk_attr, (attr.key, old, new)))

    for obj in session.deleted:
        meta = TRACKED.get(type(obj))
        if meta:
            etype, pk_attr = meta
            pending.append(("delete", obj, etype, pk_attr, getattr(obj, pk_attr, None)))


@event.listens_for(SessionLocal, "after_flush")
def _audit_after_flush(session, flush_context):
    pending = session.info.pop("_audit", None)
    if not pending:
        return

    editor = current_editor.get()
    rows = []
    for kind, obj, etype, pk_attr, extra in pending:
        if kind == "delete":
            entity_id = extra if extra is not None else getattr(obj, pk_attr, None)
        else:
            entity_id = getattr(obj, pk_attr, None)  # populated for inserts now
        if entity_id is None:
            continue

        if kind == "insert":
            rows.append(dict(
                entity_type=etype, entity_id=entity_id, field_name="created",
                old_value=None, new_value="created",
                editor=editor, edit_status="created", reviewed=False,
            ))
        elif kind == "update":
            field, old, new = extra
            rows.append(dict(
                entity_type=etype, entity_id=entity_id, field_name=field,
                old_value=_s(old), new_value=_s(new),
                editor=editor, edit_status="edited", reviewed=False,
            ))
        elif kind == "delete":
            rows.append(dict(
                entity_type=etype, entity_id=entity_id, field_name="deleted",
                old_value="deleted", new_value=None,
                editor=editor, edit_status="deleted", reviewed=False,
            ))

    if rows:
        # Core insert (not ORM add) so the listeners don't re-fire.
        session.execute(ChangeLog.__table__.insert(), rows)
