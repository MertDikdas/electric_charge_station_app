from datetime import time
from dataclasses import dataclass
from typing import Optional

from app.domain.models.base import BaseEntity


@dataclass
class ChargingSessionEntity(BaseEntity):
    reservation_id: int
    start_time: time
    end_time: Optional[time] = None
    consuming_power: float = 0.0
    cost: float = 0.0
    status: str = "PENDING"


ChargingSession = ChargingSessionEntity
