from pydantic import BaseModel
from datetime import date, time

class ReservationCreate(BaseModel):
    vehicle_id: int
    charger_id: int
    date: date
    start_time: time
    end_time: time
    status: str = "PENDING"

class Reservation(ReservationCreate):
    id: int
    user_id: int
