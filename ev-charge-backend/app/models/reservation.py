from pydantic import BaseModel
from datetime import date, time

class ReservationCreate(BaseModel):
    user_id: int
    vehicle_id: int
    charger_id: int
    date: date
    start_time: time
    end_time: time
    status: str = "active"

class Reservation(ReservationCreate):
    id: int
