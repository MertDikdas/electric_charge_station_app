from dataclasses import dataclass
from typing import Optional

from app.domain.models.base import BaseEntity


@dataclass
class ChargerEntity(BaseEntity):
    station_id: int
    connector_type: str
    current_type: str
    max_power: float = 1.0
    price_per_kwh: float = 0.0
    status: str = "AVAILABLE"
    station_name: Optional[str] = None


Charger = ChargerEntity
