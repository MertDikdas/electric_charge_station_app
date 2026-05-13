from typing import Literal, List

from pydantic import BaseModel, Field, field_validator

from app.schemas.charger import Charger


StationStatus = Literal[
    "AVAILABLE",
    "OCCUPIED",
    "OUT_OF_SERVICE",
    "MAINTENANCE",
    "CLOSED",
]


class StationCreate(BaseModel):
    name: str
    address: str
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    status: str = "AVAILABLE"


class Station(StationCreate):
    id: int
    chargers: List[Charger] = Field(default_factory=list)


class StationStatusUpdate(BaseModel):
    status: StationStatus

    @field_validator("status", mode="before")
    @classmethod
    def normalize_status(cls, value: str) -> str:
        if isinstance(value, str):
            return value.upper()
        return value

