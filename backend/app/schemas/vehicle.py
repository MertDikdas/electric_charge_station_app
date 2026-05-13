from pydantic import BaseModel, field_validator

class VehicleBase(BaseModel):
    name: str
    brand: str
    model: str
    plate: str
    max_charging_power: float
    battery_capacity: float
    connector_type: str
    current_type: str

    @field_validator("name", "brand", "model", "plate", "connector_type", "current_type")
    @classmethod
    def strip_text_fields(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Field cannot be empty")
        return value


class VehicleCreate(VehicleBase):
    pass


class Vehicle(VehicleBase):
    id: int
    user_id: int
