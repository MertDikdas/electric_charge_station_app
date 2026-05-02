from dataclasses import dataclass

from app.domain.models.base import BaseEntity


@dataclass
class StationEntity(BaseEntity):
    address: str
    company: str
    location: str
    status: str = "AVAILABLE"


Station = StationEntity
