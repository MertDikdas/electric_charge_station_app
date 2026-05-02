from pydantic import BaseModel, Field

class StationCreate(BaseModel):
    address: str
    company: str
    location: str
    status:str

class Station(StationCreate):
    id: int
