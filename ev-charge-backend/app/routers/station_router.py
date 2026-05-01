from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.models.station import StationCreate, Station
from app.core.uow import AbstractUnitOfWork
from app.core.dependencies import get_uow

router = APIRouter()

@router.post("/", response_model=Station, status_code=201)
def create_station(station: StationCreate, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        new_station = Station(**station.model_dump(), id=0)
        uow.stations.add(new_station)
        uow.commit()
        return new_station

@router.get("/", response_model=List[Station])
def get_stations(uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        return uow.stations.list()

@router.get("/{station_id}", response_model=Station)
def get_station(station_id: int, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        station = uow.stations.get(station_id)
        if not station:
            raise HTTPException(status_code=404, detail="Station not found")
        return station
