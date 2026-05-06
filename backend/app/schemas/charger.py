from typing import Literal

from pydantic import BaseModel, Field, field_validator


ConnectorType = Literal[
    "TYPE_1",
    "TYPE_2",
    "CCS1",
    "CCS2",
    "CHADEMO",
    "NACS",
    "GB_T_AC",
    "GB_T_DC",
    "TESLA_ROADSTER",
    "TESLA_TYPE_2",
]
CurrentType = Literal["AC", "DC"]
ChargerStatus = Literal[
    "AVAILABLE",
    "OCCUPIED",
    "OUT_OF_SERVICE",
    "MAINTENANCE",
    "CLOSED",
]


class ChargerCreate(BaseModel):
    station_id: int
    connector_type: ConnectorType
    current_type: CurrentType
    max_power: float = Field(default=1.0, gt=0)
    price_per_kwh: float = Field(default=0.0, ge=0)
    status: ChargerStatus = "AVAILABLE"

    @field_validator("connector_type", "current_type", "status", mode="before")
    @classmethod
    def normalize_uppercase(cls, value: str) -> str:
        if isinstance(value, str):
            return value.upper()
        return value


class Charger(ChargerCreate):
    id: int


class ChargerStatusUpdate(BaseModel):
    status: ChargerStatus

    @field_validator("status", mode="before")
    @classmethod
    def normalize_status(cls, value: str) -> str:
        if isinstance(value, str):
            return value.upper()
        return value
