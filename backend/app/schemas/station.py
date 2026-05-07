from typing import Literal

from pydantic import BaseModel, Field, field_validator


StationStatus = Literal[
    "AVAILABLE",
    "OCCUPIED",
    "OUT_OF_SERVICE",
    "MAINTENANCE",
    "CLOSED",
]

class StationCreate(BaseModel):
    address: str
    company: str
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    status: str = "AVAILABLE"

class Station(StationCreate):
    id: int


class StationStatusUpdate(BaseModel):
    status: StationStatus

    @field_validator("status", mode="before")
    @classmethod
    def normalize_status(cls, value: str) -> str:
        if isinstance(value, str):
            return value.upper()
        return value
