from pydantic import BaseModel, model_validator
import datetime as dt
from typing import Any, Optional

class ReservationCreate(BaseModel):
    vehicle_id: int
    station_id: Optional[int] = None
    charger_id: int
    date: Optional[dt.date] = None
    start_time: dt.time
    end_time: Optional[dt.time] = None
    duration_minutes: int = 120
    status: str = "PENDING"

    @model_validator(mode="before")
    @classmethod
    def normalize_datetime_range(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data

        normalized = dict(data)
        start_value = normalized.get("start_time")
        end_value = normalized.get("end_time")

        if isinstance(start_value, str) and "T" in start_value:
            start_at = dt.datetime.fromisoformat(start_value)
            normalized["date"] = start_at.date()
            normalized["start_time"] = start_at.time().replace(microsecond=0)

        if isinstance(end_value, str) and "T" in end_value:
            end_at = dt.datetime.fromisoformat(end_value)
            normalized["end_time"] = end_at.time().replace(microsecond=0)

        return normalized

    @model_validator(mode="after")
    def validate_date_present(self) -> "ReservationCreate":
        if self.date is None:
            raise ValueError("Reservation date is required")
        return self

class Reservation(ReservationCreate):
    id: int
    user_id: int
    station_id: int
    station_name: Optional[str] = None
    charger_connector_type: Optional[str] = None
    charger_current_type: Optional[str] = None


class ReservationStatusUpdate(BaseModel):
    status: str
