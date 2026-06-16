from pydantic import BaseModel, field_validator
from typing import Optional, List, Dict
import datetime as dt
from datetime import date, time, datetime
from decimal import Decimal


# ── Shared workflow fields ──────────────────────────────────────────────────

class WorkflowFields(BaseModel):
    edit_status: Optional[str] = None
    editor: Optional[str] = None
    reviewer: Optional[str] = None
    reviewed: bool = False
    review: Optional[str] = None
    reviewer_comments: Optional[str] = None


class ReviewAction(BaseModel):
    reviewer: str
    review: str                        # Approved | Pending | All Good | Clarification Needed
    reviewer_comments: Optional[str] = None


class GenericReview(BaseModel):
    entity_type: str                   # pricing | schedule_platform_entry | tour | tour_option | platform_tour
    entity_id: int
    review: str
    reviewer: Optional[str] = None
    field_name: Optional[str] = "review"


# ── Port ───────────────────────────────────────────────────────────────────

class PortOut(BaseModel):
    port_id: int
    name: str
    model_config = {"from_attributes": True}


# ── Ship ───────────────────────────────────────────────────────────────────

class ShipOut(BaseModel):
    ship_id: int
    name: str
    model_config = {"from_attributes": True}


# ── Platform ───────────────────────────────────────────────────────────────

class PlatformOut(BaseModel):
    platform_id: int
    name: str
    commission_pct: Optional[Decimal]
    applies_commission: bool
    model_config = {"from_attributes": True}


# ── Shore Excursion ────────────────────────────────────────────────────────

class ShoreExcursionOut(BaseModel):
    shorex_id: int
    name: str
    primary_port_id: Optional[int]
    model_config = {"from_attributes": True}


# ── Tour ───────────────────────────────────────────────────────────────────

class TourOut(BaseModel):
    tour_id: int
    shorex_id: int
    name: str
    status: str
    link: Optional[str]
    model_config = {"from_attributes": True}


class TourOptionOut(BaseModel):
    option_id: int
    tour_id: int
    name: str
    is_private: bool
    ship_id: Optional[int]
    base_price: Optional[Decimal]
    link: Optional[str]
    model_config = {"from_attributes": True}


class TourWithOptions(TourOut):
    options: List[TourOptionOut] = []


# ── Write schemas: tours & options ──────────────────────────────────────────
# Used by the Excel add-in to mirror Excel writes to the API.
# Name-based variants resolve ship/port/shorex/tour names on the backend so the
# frontend doesn't have to maintain ID lookups for everything.

class TourCreate(BaseModel):
    tour_id: int                           # Vexperio ID (assigned externally)
    shorex_id: Optional[int] = None        # explicit when known
    shorex_name: Optional[str] = None      # backend resolves/creates if shorex_id absent
    port_name: Optional[str] = None        # only used when creating a new shorex
    name: str
    status: str = "Draft"
    link: Optional[str] = None


class TourUpdate(BaseModel):
    shorex_id: Optional[int] = None
    shorex_name: Optional[str] = None
    name: Optional[str] = None
    status: Optional[str] = None
    link: Optional[str] = None


class TourOptionCreate(BaseModel):
    option_id: Optional[int] = None        # explicit when known (Excel uses raw int)
    name: str
    is_private: bool = False
    ship_id: Optional[int] = None
    ship_name: Optional[str] = None
    base_price: Optional[Decimal] = None
    link: Optional[str] = None


class TourOptionUpdate(BaseModel):
    name: Optional[str] = None
    is_private: Optional[bool] = None
    ship_id: Optional[int] = None
    ship_name: Optional[str] = None
    base_price: Optional[Decimal] = None
    link: Optional[str] = None


# ── Write schemas: platform tours ───────────────────────────────────────────

class PlatformTourCreate(BaseModel):
    external_id: str
    name: str
    link: Optional[str] = None
    status: Optional[str] = None
    tour_id: Optional[int] = None


class PlatformTourUpdate(BaseModel):
    external_id: Optional[str] = None
    name: Optional[str] = None
    link: Optional[str] = None
    status: Optional[str] = None
    tour_id: Optional[int] = None


# ── Write schemas: dockings & schedules ─────────────────────────────────────

class DockingCreate(BaseModel):
    ship_id: Optional[int] = None
    ship_name: Optional[str] = None
    port_id: Optional[int] = None
    port_name: Optional[str] = None
    date: date
    dock_start: Optional[time] = None
    dock_end: Optional[time] = None


class TourScheduleCreate(BaseModel):
    # Either provide IDs, or names + date and the backend resolves/creates the docking.
    docking_id: Optional[int] = None
    ship_name: Optional[str] = None
    port_name: Optional[str] = None
    # dt.date — field name `date` must not shadow datetime.date in Optional[date]
    date: Optional[dt.date] = None
    dock_start: Optional[time] = None
    dock_end: Optional[time] = None

    shorex_id: Optional[int] = None
    shorex_name: Optional[str] = None        # backend resolves; or falls back to tour_name → shorex
    tour_name: Optional[str] = None          # tour name (when shorex unknown)

    start_time: Optional[time] = None
    tour_type: str = "Shared"
    duration_hours: Optional[int] = None
    status: str = "confirmed"

    @field_validator("duration_hours", mode="before")
    @classmethod
    def _coerce_duration_hours(cls, v):
        if v is None or v == "":
            return None
        return int(round(float(v)))


class TourScheduleUpdate(BaseModel):
    shorex_id: Optional[int] = None
    shorex_name: Optional[str] = None
    tour_name: Optional[str] = None
    start_time: Optional[time] = None
    tour_type: Optional[str] = None
    duration_hours: Optional[int] = None
    status: Optional[str] = None
    # Docking re-link (e.g. ship or date changed)
    docking_id: Optional[int] = None
    ship_name: Optional[str] = None
    port_name: Optional[str] = None
    date: Optional[dt.date] = None
    dock_start: Optional[time] = None
    dock_end: Optional[time] = None

    @field_validator("duration_hours", mode="before")
    @classmethod
    def _coerce_duration_hours(cls, v):
        if v is None or v == "":
            return None
        return int(round(float(v)))


# ── Option Availability ────────────────────────────────────────────────────

class StartTimeOut(BaseModel):
    start_time_id: int
    start_time: time
    model_config = {"from_attributes": True}


class BlockedPeriodOut(BaseModel):
    blocked_id: int
    date_from: date
    date_to: date
    reason: Optional[str]
    model_config = {"from_attributes": True}


class BlockedPeriodIn(BaseModel):
    date_from: date
    date_to: date
    reason: Optional[str] = None


class AvailabilityOut(BaseModel):
    availability_id: int
    option_id: int
    schedule_type: str
    valid_from: date
    valid_to: Optional[date]
    mon: bool
    tue: bool
    wed: bool
    thu: bool
    fri: bool
    sat: bool
    sun: bool
    cms_status: str
    start_times: List[StartTimeOut] = []
    blocked_periods: List[BlockedPeriodOut] = []
    model_config = {"from_attributes": True}


class AvailabilityIn(BaseModel):
    schedule_type: str = "weekly_recurring"
    valid_from: date
    valid_to: Optional[date] = None
    mon: bool = False
    tue: bool = False
    wed: bool = False
    thu: bool = False
    fri: bool = False
    sat: bool = False
    sun: bool = False
    cms_status: str = "Active"
    start_times: List[time] = []
    blocked_periods: List[BlockedPeriodIn] = []


# ── Platform Tours & Options ───────────────────────────────────────────────

class PlatformOptionOut(BaseModel):
    platform_option_id: int
    platform_tour_id: int
    external_option_id: Optional[str]
    name: str
    vex_option_id: Optional[int]
    ship_id: Optional[int]
    link: Optional[str]
    model_config = {"from_attributes": True}


class PlatformOptionCreate(BaseModel):
    external_option_id: Optional[str] = None
    name: str
    vex_option_id: Optional[int] = None
    ship_id: Optional[int] = None
    link: Optional[str] = None


class PlatformOptionPatch(BaseModel):
    external_option_id: Optional[str] = None
    name: Optional[str] = None
    vex_option_id: Optional[int] = None
    ship_id: Optional[int] = None
    link: Optional[str] = None


class PlatformTourOut(BaseModel):
    platform_tour_id: int
    platform_id: int
    external_id: str
    name: str
    link: Optional[str]
    status: Optional[str]
    tour_id: Optional[int]
    options: List[PlatformOptionOut] = []
    model_config = {"from_attributes": True}


# ── Schedule ───────────────────────────────────────────────────────────────

class DockingOut(BaseModel):
    docking_id: int
    ship_id: int
    port_id: int
    date: date
    dock_start: Optional[time]
    dock_end: Optional[time]
    model_config = {"from_attributes": True}


class ScheduleEntryCreate(BaseModel):
    vex_option_id: Optional[int] = None
    platform_option_id: Optional[int] = None
    expected_price: Optional[Decimal] = None


class ScheduleEntryOut(BaseModel):
    entry_id: int
    schedule_id: int
    vex_option_id: Optional[int]
    platform_option_id: Optional[int]
    expected_price: Optional[Decimal]
    entry_status: Optional[str]
    edit_status: Optional[str]
    editor: Optional[str]
    reviewer: Optional[str]
    reviewed: bool
    review: Optional[str]
    model_config = {"from_attributes": True}


class ScheduleEntryEnriched(BaseModel):
    """SchedulePlatformEntry with all joined context — mirrors the frontend SCHEDULE_PRICING shape."""
    entry_id: int
    schedule_id: int
    # departure context
    date: Optional[date] = None
    ship: Optional[str] = None
    port: Optional[str] = None
    dock_start: Optional[time] = None
    start_time: Optional[time] = None
    # tour / option context
    shorex: Optional[str] = None
    shorex_id: Optional[int] = None
    tour_name: Optional[str] = None
    tour_id: Optional[int] = None
    option_name: Optional[str] = None
    vex_option_id: Optional[int] = None
    # platform context
    platform: Optional[str] = None
    platform_listing_id: Optional[str] = None
    platform_listing_name: Optional[str] = None
    external_option_id: Optional[str] = None
    link: Optional[str] = None
    # price & workflow
    expected_price: Optional[Decimal] = None
    entry_status: Optional[str] = None
    edit_status: Optional[str] = None
    editor: Optional[str] = None
    reviewer: Optional[str] = None
    reviewed: bool = False
    review: Optional[str] = None


class ScheduleEntryUpdate(WorkflowFields):
    expected_price: Optional[Decimal] = None
    entry_status: Optional[str] = None


class ScheduleEntryBatchCreate(BaseModel):
    vex_option_ids: List[int]
    include_platforms: bool = True
    platform_map: Optional[Dict[int, List[int]]] = None


class TourScheduleOut(BaseModel):
    schedule_id: int
    docking_id: int
    shorex_id: int
    start_time: Optional[time]
    tour_type: str
    duration_hours: Optional[int]
    status: str
    platform_entries: List[ScheduleEntryOut] = []
    model_config = {"from_attributes": True}


# ── Departure ──────────────────────────────────────────────────────────────

class DepartureOut(BaseModel):
    departure_id: int
    option_id: int
    departure_date: date
    start_time: time
    source: str
    availability_id: Optional[int]
    docking_id: Optional[int]
    status: str
    manually_closed: bool
    closed_by: Optional[str]
    closed_at: Optional[datetime]
    close_reason: Optional[str]
    max_pax: Optional[int]
    model_config = {"from_attributes": True}


class DepartureCreate(BaseModel):
    option_id: int
    departure_date: date
    start_time: time
    source: str = "manual"
    availability_id: Optional[int] = None
    docking_id: Optional[int] = None
    max_pax: Optional[int] = None


class DepartureClose(BaseModel):
    closed_by: str
    close_reason: Optional[str] = None


# ── Pricing ────────────────────────────────────────────────────────────────

class PricingOut(BaseModel):
    pricing_id: int
    shorex_id: int
    platform_id: int
    platform_tour_id: Optional[int]
    vex_option_id: Optional[int]
    price: Optional[Decimal]
    commission_pct: Optional[Decimal]
    promo_name: Optional[str]
    promo_pct: Optional[Decimal]
    promo_end_date: Optional[date]
    platform_status: Optional[str]
    link: Optional[str]
    change_status: Optional[str]
    editor: Optional[str]
    reviewer: Optional[str]
    reviewed: bool
    review: Optional[str]
    updated_at: Optional[datetime]
    model_config = {"from_attributes": True}


class PricingCreate(BaseModel):
    shorex_id: int
    platform_id: int
    platform_tour_id: Optional[int] = None
    vex_option_id: Optional[int] = None
    price: Optional[Decimal] = None
    commission_pct: Optional[Decimal] = None
    promo_name: Optional[str] = None
    promo_pct: Optional[Decimal] = None
    promo_end_date: Optional[date] = None
    platform_status: Optional[str] = None
    link: Optional[str] = None
    change_status: Optional[str] = None
    editor: Optional[str] = None


class PricingUpdate(BaseModel):
    price: Optional[Decimal] = None
    commission_pct: Optional[Decimal] = None
    platform_status: Optional[str] = None
    change_status: Optional[str] = None
    editor: Optional[str] = None
    promo_name: Optional[str] = None
    promo_pct: Optional[Decimal] = None
    promo_end_date: Optional[date] = None


# ── Users (shared people list) ──────────────────────────────────────────────

class UserOut(BaseModel):
    user_id: int
    name: str
    email: Optional[str] = None
    active: bool

    model_config = {"from_attributes": True}


class UserCreate(BaseModel):
    name: str
    email: Optional[str] = None


# ── Discount ───────────────────────────────────────────────────────────────

class DiscountOut(BaseModel):
    discount_id: int
    name: str
    platform_id: Optional[int]
    shorex_id: Optional[int]
    tour_id: Optional[int]
    option_id: Optional[int]
    platform_option_id: Optional[int]
    discount_pct: Decimal
    valid_from: date
    valid_to: Optional[date]
    status: str
    model_config = {"from_attributes": True}


class DiscountCreate(BaseModel):
    name: str
    platform_id: Optional[int] = None
    shorex_id: Optional[int] = None
    tour_id: Optional[int] = None
    option_id: Optional[int] = None
    platform_option_id: Optional[int] = None
    discount_pct: Decimal
    valid_from: date
    valid_to: Optional[date] = None
    created_by: Optional[str] = None
    notes: Optional[str] = None


class DiscountUpdate(BaseModel):
    name: Optional[str] = None
    discount_pct: Optional[Decimal] = None
    valid_from: Optional[date] = None
    valid_to: Optional[date] = None
    notes: Optional[str] = None
    status: Optional[str] = None


# ── Commission ─────────────────────────────────────────────────────────────

class CommissionOut(BaseModel):
    commission_id: int
    platform_id: int
    shorex_id: Optional[int]
    tour_id: Optional[int]
    option_id: Optional[int]
    commission_pct: Decimal
    valid_from: date
    valid_to: Optional[date]
    notes: Optional[str]
    model_config = {"from_attributes": True}


class CommissionCreate(BaseModel):
    platform_id: int
    shorex_id: Optional[int] = None
    tour_id: Optional[int] = None
    option_id: Optional[int] = None
    commission_pct: Decimal
    valid_from: date
    valid_to: Optional[date] = None
    notes: Optional[str] = None


# ── Notes ─────────────────────────────────────────────────────────────────

class NoteOut(BaseModel):
    note_id: int
    entity_type: str
    entity_id: int
    note_type: str
    body: str
    author: Optional[str]
    created_at: datetime
    model_config = {"from_attributes": True}


class NoteCreate(BaseModel):
    note_type: str = "general"         # change | review | general
    body: str
    author: Optional[str] = None


# ── Change Log ─────────────────────────────────────────────────────────────

class ChangeLogOut(BaseModel):
    log_id: int
    entity_type: str
    entity_id: int
    field_name: Optional[str]
    old_value: Optional[str]
    new_value: Optional[str]
    editor: Optional[str]
    edit_status: Optional[str]
    reviewer: Optional[str]
    reviewed: bool
    review: Optional[str]
    changed_at: datetime
    reviewed_at: Optional[datetime]
    model_config = {"from_attributes": True}


# ── Guidelines ─────────────────────────────────────────────────────────────

class GuidelineAttributeOut(BaseModel):
    attribute_id: int
    key_name: str
    value_text: str
    order_index: int
    model_config = {"from_attributes": True}

class GuidelineOut(BaseModel):
    guideline_id: int
    type: str
    entity_name: Optional[str]
    platform_id: Optional[int]
    port_id: Optional[int]
    updated_by: Optional[str]
    created_at: datetime
    updated_at: datetime
    attributes: List[GuidelineAttributeOut] = []
    model_config = {"from_attributes": True}

class GuidelineAttributePayload(BaseModel):
    key_name: str
    value_text: str

class GuidelinesSyncPayload(BaseModel):
    general: List[GuidelineAttributePayload] = []
    platforms: Dict[str, List[GuidelineAttributePayload]] = {}
    ports: Dict[str, List[GuidelineAttributePayload]] = {}
    updated_by: Optional[str] = None

