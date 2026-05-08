from dataclasses import dataclass, field
from typing import List

from app.domain.models.base import BaseEntity
from app.domain.models.charger import ChargerEntity

@dataclass
class StationEntity(BaseEntity):
    address: str
    latitude: float
    longitude: float
    company_id: int
    status: str = "AVAILABLE"
    chargers: List[ChargerEntity] = field(default_factory=list)


Station = StationEntity
