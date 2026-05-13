from datetime import date, time
from typing import Optional
from dataclasses import dataclass

from app.domain.models.base import BaseEntity


@dataclass
class ReservationEntity(BaseEntity):
    user_id: int
    vehicle_id: int
    charger_id: int
    date: date
    start_time: time
    station_id: Optional[int] = None
    end_time: Optional[time] = None
    duration_minutes: int = 120
    status: str = "PENDING"
    station_name: Optional[str] = None
    charger_connector_type: Optional[str] = None
    charger_current_type: Optional[str] = None


Reservation = ReservationEntity
