from dataclasses import dataclass

from app.domain.models.base import BaseEntity
from app.domain.models.charger import ChargerEntity
from typing import List
from dataclasses import field

@dataclass
class StationEntity(BaseEntity):
    address: str
    latitude: float
    longitude: float
    company_id: int
    status: str = "AVAILABLE"
    chargers: List[ChargerEntity] = field(default_factory=list)


Station = StationEntity
