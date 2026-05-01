from pydantic import BaseModel
from datetime import time
from typing import Optional

class ChargingSessionCreate(BaseModel):
    reservation_id: int
    start_time: time
    end_time: Optional[time] = None
    consuming_power: float = 0.0
    cost: float = 0.0
    status: str = "active"

class ChargingSession(ChargingSessionCreate):
    # Diagram uses double line which means Weak Entity, 
    # it depends on Reservation. We use reservation_id as the relation.
    pass
