from pydantic import BaseModel, Field

class VehicleCreate(BaseModel):
    user_id: int
    model: str
    plate: str
    max_charging_power: float
    battery_capacity: float
    connector_type: str
    current_type: str

class Vehicle(VehicleCreate):
    id: int