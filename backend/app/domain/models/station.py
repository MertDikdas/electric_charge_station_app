from dataclasses import dataclass

from app.domain.models.base import BaseEntity


@dataclass
class StationEntity(BaseEntity):
    address: str
    company: str
    latitude: float
    longitude: float
    status: str = "AVAILABLE"


Station = StationEntity
