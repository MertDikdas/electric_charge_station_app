from pydantic import BaseModel, Field

class StationCreate(BaseModel):
    address: str
    company: str
    location: str

class Station(StationCreate):
    id: int
