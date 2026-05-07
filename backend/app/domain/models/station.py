from dataclasses import dataclass

from app.domain.models.base import BaseEntity
from app.domain.models.charger import ChargerEntity
from typing import List, Optional, Dict, Any
from dataclasses import field

@dataclass
class StationEntity(BaseEntity):
    address: str
    company: str
    latitude: float
    longitude: float
    status: str = "AVAILABLE"
    chargers: List[ChargerEntity] = field(default_factory=list)


Station = StationEntity
