from pydantic import BaseModel, Field

class StationCreate(BaseModel):
    address: str
    company: str
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    status: str = "AVAILABLE"

class Station(StationCreate):
    id: int
