from datetime import date, time
from dataclasses import dataclass

from app.domain.models.base import BaseEntity


@dataclass
class ReservationEntity(BaseEntity):
    user_id: int
    vehicle_id: int
    charger_id: int
    date: date
    start_time: time
    end_time: time
    status: str = "PENDING"


Reservation = ReservationEntity
