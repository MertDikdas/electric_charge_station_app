from pydantic import BaseModel, Field

class ChargerCreate(BaseModel):
    station_id: int
    connector_type: str
    current_type: str
    status: str = "available"

class Charger(ChargerCreate):
    id: int
