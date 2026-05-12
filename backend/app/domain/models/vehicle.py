from dataclasses import dataclass

from app.domain.models.base import BaseEntity


@dataclass
class VehicleEntity(BaseEntity):
    user_id: int
    name: str
    brand: str
    model: str
    plate: str
    max_charging_power: float
    battery_capacity: float
    connector_type: str
    current_type: str
    is_active: bool = True


Vehicle = VehicleEntity
