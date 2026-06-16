from sqlalchemy import (
    Column, Integer, String, Boolean, Numeric, Date, Time,
    DateTime, Text, ForeignKey, UniqueConstraint
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from api.database import Base


class Port(Base):
    __tablename__ = "port"
    port_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False, unique=True)


class Ship(Base):
    __tablename__ = "ship"
    ship_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False, unique=True)


class Platform(Base):
    __tablename__ = "platform"
    platform_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False, unique=True)
    commission_pct = Column(Numeric(6, 4))
    applies_commission = Column(Boolean, nullable=False, default=True)


class User(Base):
    __tablename__ = "app_user"
    user_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False)
    email = Column(String, nullable=True)
    active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class ShoreExcursion(Base):
    __tablename__ = "shore_excursion"
    shorex_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False, unique=True)
    primary_port_id = Column(Integer, ForeignKey("port.port_id"))

    port = relationship("Port")
    tours = relationship("Tour", back_populates="shore_excursion")


class Tour(Base):
    __tablename__ = "tour"
    tour_id = Column(Integer, primary_key=True)
    shorex_id = Column(Integer, ForeignKey("shore_excursion.shorex_id"), nullable=False)
    name = Column(String, nullable=False)
    status = Column(String, nullable=False)
    link = Column(String)

    shore_excursion = relationship("ShoreExcursion", back_populates="tours")
    options = relationship("TourOption", back_populates="tour")


class TourOption(Base):
    __tablename__ = "tour_option"
    option_id = Column(Integer, primary_key=True, autoincrement=True)
    tour_id = Column(Integer, ForeignKey("tour.tour_id"), nullable=False)
    name = Column(String, nullable=False)
    is_private = Column(Boolean, nullable=False, default=False)
    ship_id = Column(Integer, ForeignKey("ship.ship_id"))
    base_price = Column(Numeric(10, 2))
    link = Column(String)

    tour = relationship("Tour", back_populates="options")
    ship = relationship("Ship")
    availabilities = relationship("OptionAvailability", back_populates="option")


class OptionAvailability(Base):
    __tablename__ = "option_availability"
    availability_id = Column(Integer, primary_key=True, autoincrement=True)
    option_id = Column(Integer, ForeignKey("tour_option.option_id"), nullable=False)
    schedule_type = Column(String, nullable=False, default="weekly_recurring")
    valid_from = Column(Date, nullable=False)
    valid_to = Column(Date)
    mon = Column(Boolean, nullable=False, default=False)
    tue = Column(Boolean, nullable=False, default=False)
    wed = Column(Boolean, nullable=False, default=False)
    thu = Column(Boolean, nullable=False, default=False)
    fri = Column(Boolean, nullable=False, default=False)
    sat = Column(Boolean, nullable=False, default=False)
    sun = Column(Boolean, nullable=False, default=False)
    cms_status = Column(String, nullable=False, default="Active")

    option = relationship("TourOption", back_populates="availabilities")
    start_times = relationship("OptionStartTime", back_populates="availability", cascade="all, delete-orphan")
    blocked_periods = relationship("OptionBlockedPeriod", back_populates="availability", cascade="all, delete-orphan")


class OptionStartTime(Base):
    __tablename__ = "option_start_time"
    start_time_id = Column(Integer, primary_key=True, autoincrement=True)
    availability_id = Column(Integer, ForeignKey("option_availability.availability_id", ondelete="CASCADE"), nullable=False)
    start_time = Column(Time, nullable=False)

    availability = relationship("OptionAvailability", back_populates="start_times")


class OptionBlockedPeriod(Base):
    __tablename__ = "option_blocked_period"
    blocked_id = Column(Integer, primary_key=True, autoincrement=True)
    availability_id = Column(Integer, ForeignKey("option_availability.availability_id", ondelete="CASCADE"), nullable=False)
    date_from = Column(Date, nullable=False)
    date_to = Column(Date, nullable=False)
    reason = Column(Text)

    availability = relationship("OptionAvailability", back_populates="blocked_periods")


class PlatformTour(Base):
    __tablename__ = "platform_tour"
    platform_tour_id = Column(Integer, primary_key=True, autoincrement=True)
    platform_id = Column(Integer, ForeignKey("platform.platform_id"), nullable=False)
    external_id = Column(String, nullable=False)
    name = Column(String, nullable=False)
    link = Column(String)
    status = Column(String)
    tour_id = Column(Integer, ForeignKey("tour.tour_id"))

    platform = relationship("Platform")
    tour = relationship("Tour")
    options = relationship("PlatformOption", back_populates="platform_tour")

    __table_args__ = (UniqueConstraint("platform_id", "external_id"),)


class PlatformOption(Base):
    __tablename__ = "platform_option"
    platform_option_id = Column(Integer, primary_key=True, autoincrement=True)
    platform_tour_id = Column(Integer, ForeignKey("platform_tour.platform_tour_id"), nullable=False)
    external_option_id = Column(String)
    name = Column(String, nullable=False)
    vex_option_id = Column(Integer, ForeignKey("tour_option.option_id"))
    ship_id = Column(Integer, ForeignKey("ship.ship_id"))
    link = Column(String)

    platform_tour = relationship("PlatformTour", back_populates="options")
    vex_option = relationship("TourOption")
    ship = relationship("Ship")


class ShipDocking(Base):
    __tablename__ = "ship_docking"
    docking_id = Column(Integer, primary_key=True, autoincrement=True)
    ship_id = Column(Integer, ForeignKey("ship.ship_id"), nullable=False)
    port_id = Column(Integer, ForeignKey("port.port_id"), nullable=False)
    date = Column(Date, nullable=False)
    dock_start = Column(Time)
    dock_end = Column(Time)

    ship = relationship("Ship")
    port = relationship("Port")
    schedules = relationship("TourSchedule", back_populates="docking")

    __table_args__ = (UniqueConstraint("ship_id", "date"),)


class TourSchedule(Base):
    __tablename__ = "tour_schedule"
    schedule_id = Column(Integer, primary_key=True, autoincrement=True)
    docking_id = Column(Integer, ForeignKey("ship_docking.docking_id"), nullable=False)
    shorex_id = Column(Integer, ForeignKey("shore_excursion.shorex_id"), nullable=False)
    start_time = Column(Time)
    tour_type = Column(String, nullable=False)
    duration_hours = Column(Integer)
    status = Column(String, nullable=False)

    docking = relationship("ShipDocking", back_populates="schedules")
    shore_excursion = relationship("ShoreExcursion")
    platform_entries = relationship("SchedulePlatformEntry", back_populates="schedule")

    __table_args__ = (UniqueConstraint("docking_id", "shorex_id", "tour_type", "start_time"),)


class SchedulePlatformEntry(Base):
    __tablename__ = "schedule_platform_entry"
    entry_id = Column(Integer, primary_key=True, autoincrement=True)
    schedule_id = Column(Integer, ForeignKey("tour_schedule.schedule_id"), nullable=False)
    vex_option_id = Column(Integer, ForeignKey("tour_option.option_id"))
    platform_option_id = Column(Integer, ForeignKey("platform_option.platform_option_id"))
    expected_price = Column(Numeric(10, 2))
    entry_status = Column(String)
    edit_status = Column(String)
    editor = Column(String)
    reviewer = Column(String)
    reviewed = Column(Boolean, nullable=False, default=False)
    review = Column(String)
    # comments live in Note table (entity_type='schedule_platform_entry')

    schedule = relationship("TourSchedule", back_populates="platform_entries")
    vex_option = relationship("TourOption", foreign_keys=[vex_option_id])
    platform_option = relationship("PlatformOption", foreign_keys=[platform_option_id])


class Departure(Base):
    __tablename__ = "departure"
    departure_id = Column(Integer, primary_key=True, autoincrement=True)
    option_id = Column(Integer, ForeignKey("tour_option.option_id"), nullable=False)
    departure_date = Column(Date, nullable=False)
    start_time = Column(Time, nullable=False)
    source = Column(String, nullable=False)
    availability_id = Column(Integer, ForeignKey("option_availability.availability_id"))
    docking_id = Column(Integer, ForeignKey("ship_docking.docking_id"))
    status = Column(String, nullable=False, default="open")
    manually_closed = Column(Boolean, nullable=False, default=False)
    closed_by = Column(String)
    closed_at = Column(DateTime(timezone=True))
    close_reason = Column(Text)
    max_pax = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    option = relationship("TourOption")
    availability = relationship("OptionAvailability")
    docking = relationship("ShipDocking")

    __table_args__ = (UniqueConstraint("option_id", "departure_date", "start_time"),)


class Pricing(Base):
    __tablename__ = "pricing"
    pricing_id = Column(Integer, primary_key=True, autoincrement=True)
    shorex_id = Column(Integer, ForeignKey("shore_excursion.shorex_id"), nullable=False)
    platform_id = Column(Integer, ForeignKey("platform.platform_id"), nullable=False)
    platform_tour_id = Column(Integer, ForeignKey("platform_tour.platform_tour_id"))
    vex_option_id = Column(Integer, ForeignKey("tour_option.option_id"))
    price = Column(Numeric(10, 2))
    commission_pct = Column(Numeric(6, 4))
    promo_name = Column(String)
    promo_pct = Column(Numeric(6, 4))
    promo_end_date = Column(Date)
    platform_status = Column(String)
    link = Column(String)
    change_status = Column(String)
    editor = Column(String)
    reviewer = Column(String)
    reviewed = Column(Boolean, nullable=False, default=False)
    review = Column(String)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    shore_excursion = relationship("ShoreExcursion")
    platform = relationship("Platform")
    platform_tour = relationship("PlatformTour")
    vex_option = relationship("TourOption")

    __table_args__ = (
        UniqueConstraint("shorex_id", "platform_id", "platform_tour_id", "vex_option_id",
                         name="pricing_grain_key"),
    )


class PricingHistory(Base):
    __tablename__ = "pricing_history"
    history_id = Column(Integer, primary_key=True, autoincrement=True)
    pricing_id = Column(Integer, nullable=False)
    shorex_id = Column(Integer, nullable=False)
    platform_id = Column(Integer, nullable=False)
    platform_tour_id = Column(Integer)
    price = Column(Numeric(10, 2))
    commission_pct = Column(Numeric(6, 4))
    promo_name = Column(String)
    promo_pct = Column(Numeric(6, 4))
    promo_end_date = Column(Date)
    platform_status = Column(String)
    change_details = Column(Text)
    change_status = Column(String)
    editor = Column(String)
    reviewer = Column(String)
    review = Column(String)
    reviewer_comments = Column(Text)
    snapshotted_at = Column(DateTime(timezone=True), server_default=func.now())


class Note(Base):
    __tablename__ = "note"
    note_id = Column(Integer, primary_key=True, autoincrement=True)
    entity_type = Column(String, nullable=False)
    entity_id = Column(Integer, nullable=False)
    note_type = Column(String, nullable=False, default="general")  # change | review | general
    body = Column(Text, nullable=False)
    author = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class ChangeLog(Base):
    __tablename__ = "change_log"
    log_id = Column(Integer, primary_key=True, autoincrement=True)
    entity_type = Column(String, nullable=False)
    entity_id = Column(Integer, nullable=False)
    field_name = Column(String)
    old_value = Column(Text)
    new_value = Column(Text)
    editor = Column(String)
    edit_status = Column(String)
    reviewer = Column(String)
    reviewed = Column(Boolean, nullable=False, default=False)
    review = Column(String)
    changed_at = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_at = Column(DateTime(timezone=True))


class PlatformCommission(Base):
    __tablename__ = "platform_commission"
    commission_id = Column(Integer, primary_key=True, autoincrement=True)
    platform_id = Column(Integer, ForeignKey("platform.platform_id"), nullable=False)
    shorex_id = Column(Integer, ForeignKey("shore_excursion.shorex_id"))
    tour_id = Column(Integer, ForeignKey("tour.tour_id"))
    option_id = Column(Integer, ForeignKey("tour_option.option_id"))
    commission_pct = Column(Numeric(6, 4), nullable=False)
    valid_from = Column(Date, nullable=False)
    valid_to = Column(Date)
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    platform = relationship("Platform")


class Discount(Base):
    __tablename__ = "discount"
    discount_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False)
    platform_id = Column(Integer, ForeignKey("platform.platform_id"))
    shorex_id = Column(Integer, ForeignKey("shore_excursion.shorex_id"))
    tour_id = Column(Integer, ForeignKey("tour.tour_id"))
    option_id = Column(Integer, ForeignKey("tour_option.option_id"))
    platform_option_id = Column(Integer, ForeignKey("platform_option.platform_option_id"))
    discount_pct = Column(Numeric(6, 4), nullable=False)
    valid_from = Column(Date, nullable=False)
    valid_to = Column(Date)
    status = Column(String, nullable=False, default="active")
    created_by = Column(String)
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    platform = relationship("Platform")
    platform_option = relationship("PlatformOption")

class Guideline(Base):
    __tablename__ = "guideline"
    guideline_id = Column(Integer, primary_key=True, autoincrement=True)
    type = Column(String, nullable=False)
    entity_name = Column(String)
    platform_id = Column(Integer, ForeignKey("platform.platform_id"))
    port_id = Column(Integer, ForeignKey("port.port_id"))
    updated_by = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    attributes = relationship("GuidelineAttribute", back_populates="guideline", cascade="all, delete-orphan")

class GuidelineAttribute(Base):
    __tablename__ = "guideline_attribute"
    attribute_id = Column(Integer, primary_key=True, autoincrement=True)
    guideline_id = Column(Integer, ForeignKey("guideline.guideline_id", ondelete="CASCADE"), nullable=False)
    key_name = Column(Text, nullable=False)
    value_text = Column(Text, nullable=False)
    order_index = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    guideline = relationship("Guideline", back_populates="attributes")
