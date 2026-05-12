from pydantic import BaseModel
from datetime import date, time
from typing import Optional

class ReservationCreate(BaseModel):
    vehicle_id: int
    charger_id: int
    date: date
    start_time: time
    end_time: Optional[time] = None
    duration_minutes: int = 120
    status: str = "PENDING"

class Reservation(ReservationCreate):
    id: int
    user_id: int


class ReservationStatusUpdate(BaseModel):
    status: str
