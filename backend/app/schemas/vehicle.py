from pydantic import BaseModel

class VehicleBase(BaseModel):
    name: str
    brand: str
    model: str
    plate: str
    max_charging_power: float
    battery_capacity: float
    connector_type: str
    current_type: str


class VehicleCreate(VehicleBase):
    pass


class Vehicle(VehicleBase):
    id: int
    user_id: int
