from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.station_service import StationService
from app.core.dependencies import get_station_service
from app.domain.models.station import StationCreate, Station

router = APIRouter()


@router.post("/", response_model=Station, status_code=201)
def create_station(
    station: StationCreate,
    service: StationService = Depends(get_station_service),
):
    return service.create_station(station)


@router.get("/", response_model=List[Station])
def get_stations(service: StationService = Depends(get_station_service)):
    return service.get_all_stations()


@router.get("/{station_id}", response_model=Station)
def get_station(
    station_id: int,
    service: StationService = Depends(get_station_service),
):
    station = service.get_station(station_id)
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")
    return station
