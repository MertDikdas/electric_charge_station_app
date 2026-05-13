from pydantic import BaseModel
from datetime import date, time
from typing import Optional

class ReservationCreate(BaseModel):
    vehicle_id: int
    station_id: Optional[int] = None
    charger_id: int
    date: date
    start_time: time
    end_time: Optional[time] = None
    duration_minutes: int = 120
    status: str = "PENDING"

class Reservation(ReservationCreate):
    id: int
    user_id: int
    station_id: int
    station_name: Optional[str] = None
    charger_connector_type: Optional[str] = None
    charger_current_type: Optional[str] = None


class ReservationStatusUpdate(BaseModel):
    status: str
