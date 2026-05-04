from sqlalchemy import CheckConstraint, Column, Boolean, Date, DateTime, Float, ForeignKey, Integer, String, Time
from datetime import datetime
from sqlalchemy.orm import relationship
from app.infrastructure.database.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    surname = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    balance = Column(Float, default=0.0)

    vehicles = relationship("Vehicle", back_populates="user")
    reservations = relationship("Reservation", back_populates="user")
    notifications = relationship("Notification", back_populates="user")

class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    plate = Column(String, nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False)
    model = Column(String, nullable=False)
    current_type = Column(String, nullable=False)
    connector_type = Column(String, nullable=False)
    battery_capacity = Column(Float, nullable=False)
    max_charging_power = Column(Float, nullable=False)

    __table_args__ = (
        CheckConstraint("current_type IN ('AC', 'DC')", name="check_vehicle_current_type"),
        CheckConstraint("connector_type IN ('TYPE_1', 'TYPE_2', 'CCS1', 'CCS2', 'CHADEMO', 'NACS', 'GB_T_AC', 'GB_T_DC', 'TESLA_ROADSTER', 'TESLA_TYPE_2')", name="check_vehicle_connector_type"),
        CheckConstraint("battery_capacity > 0", name="check_vehicle_battery_capacity_positive"),
        CheckConstraint("max_charging_power > 0", name="check_vehicle_max_charging_power_positive"),
    )
    reservations = relationship("Reservation", back_populates="vehicle")
    user = relationship("User", back_populates="vehicles")

class Station(Base):
    __tablename__ = "stations"

    id = Column(Integer, primary_key=True, index=True)
    company = Column(String, nullable=False)
    location = Column(String, nullable=False, index=True)
    address = Column(String, nullable=False)
    status = Column(String, nullable=False, default="AVAILABLE")


    __table_args__ = (
        CheckConstraint("status IN ('AVAILABLE', 'OCCUPIED', 'OUT_OF_SERVICE', 'MAINTENANCE', 'CLOSED')", name="check_station_status"),
    )
    chargers = relationship("Charger", back_populates="station")

class Charger(Base):
    __tablename__ = "chargers"

    id = Column(Integer, primary_key=True, index=True)
    station_id = Column(Integer, ForeignKey("stations.id"), index=True, nullable=False)
    connector_type = Column(String, nullable=False)
    current_type = Column(String, nullable=False)
    max_power = Column(Float, nullable=False)
    price_per_kwh = Column(Float, nullable=False)
    status = Column(String, nullable=False, default="AVAILABLE")

    __table_args__ = (
        CheckConstraint("connector_type IN ('TYPE_1', 'TYPE_2', 'CCS1', 'CCS2', 'CHADEMO', 'NACS', 'GB_T_AC', 'GB_T_DC', 'TESLA_ROADSTER', 'TESLA_TYPE_2')", name="check_charger_connector_type"),
        CheckConstraint("max_power > 0", name="check_charger_max_power_positive"),
        CheckConstraint("price_per_kwh >= 0", name="check_charger_price_per_kwh_non_negative"),
        CheckConstraint("current_type IN ('AC', 'DC')", name="check_charger_current_type"),
        CheckConstraint("status IN ('AVAILABLE', 'OCCUPIED', 'OUT_OF_SERVICE', 'MAINTENANCE', 'CLOSED')", name="check_charger_status"),
    )
    station = relationship("Station", back_populates="chargers")
    reservations = relationship("Reservation", back_populates="charger")

class Reservation(Base):
    __tablename__ = "reservations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"), index=True, nullable=False)
    charger_id = Column(Integer, ForeignKey("chargers.id"), index=True, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    date = Column(Date, nullable=False)
    status = Column(String, nullable=False, default="PENDING")

    __table_args__ = (
        CheckConstraint("status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED','EXPIRED', 'NO_SHOW')", name="check_reservation_status"),
        CheckConstraint("end_time > start_time", name="check_reservation_time_valid"),
        )

    user = relationship("User", back_populates="reservations")
    vehicle = relationship("Vehicle", back_populates="reservations")
    charger = relationship("Charger", back_populates="reservations")
    charging_session = relationship("ChargingSession", back_populates="reservation", uselist=False)

class ChargingSession(Base):
    __tablename__ = "charging_sessions"

    reservation_id = Column(Integer, ForeignKey("reservations.id"), primary_key=True, index=True, nullable=False)
    consuming_power = Column(Float, nullable=False, default=0.0)
    cost = Column(Float, nullable=False, default=0.0)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=True)
    status = Column(String, nullable=False, default="PENDING")

    __table_args__ = (
        CheckConstraint("status IN ('STARTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'FAILED', 'INTERRUPTED', 'PENDING')", name="check_charging_session_status"),
        CheckConstraint("end_time IS NULL OR end_time > start_time", name="check_charging_session_time_valid"),
        CheckConstraint("consuming_power >= 0", name="check_charging_session_consuming_power_non_negative"),
        CheckConstraint("cost >= 0", name="check_charging_session_cost_non_negative"),
    )

    reservation = relationship("Reservation", back_populates="charging_session")

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    notification_type = Column(String, nullable=False, default="INFO")
    is_read = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint("notification_type IN ('INFO', 'SUCCESS', 'WARNING', 'ERROR')", name="check_notification_type"),
    )

    user = relationship("User", back_populates="notifications")
