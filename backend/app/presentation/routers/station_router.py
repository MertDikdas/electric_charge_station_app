from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query

from app.application.services.station_service import StationService
from app.core.dependencies import (
    AuthenticatedUser,
    get_admin_or_station_manager,
    get_only_station_manager,
    get_station_service,
    get_station_staff,
)
from app.domain.models.station import StationEntity
from app.schemas.charger import Charger
from app.schemas.station import StationCreate, Station, StationStatusUpdate
from app.domain.rules.station_rules import validate_station_entity

router = APIRouter()


@router.post("/", response_model=Station, status_code=201)
def create_station(
    station: StationCreate,
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_only_station_manager),
):
    station_entity = StationEntity(**station.model_dump())
    try:
        validate_station_entity(station_entity)
        return service.create_station(station_entity)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))



@router.get("/", response_model=List[Station])
def get_stations(service: StationService = Depends(get_station_service)):
    return service.get_all_stations()


@router.get("/nearby", response_model=List[Station])
def get_nearby_stations(
    location: str = Query(..., min_length=1),
    service: StationService = Depends(get_station_service),
):
    return service.get_nearby_stations(location)


@router.get("/{station_id}/chargers", response_model=List[Charger])
def get_station_chargers(
    station_id: int,
    service: StationService = Depends(get_station_service),
):
    station = service.get_station(station_id)
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")

    return service.get_station_chargers(station_id)


@router.get("/{station_id}", response_model=Station)
def get_station(
    station_id: int,
    service: StationService = Depends(get_station_service),
):
    station = service.get_station(station_id)
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")
    return station


@router.put("/{station_id}", response_model=Station)
def update_station(
    station_id: int,
    station: StationCreate,
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_only_station_manager),
):
    
    existing_station = service.get_station(station_id)
    if not existing_station:
        raise HTTPException(status_code=404, detail="Station not found")

    updated_station = StationEntity(id=station_id, **station.model_dump())
    try:
        validate_station_entity(updated_station)
        return service.update_station(updated_station)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/{station_id}/status", response_model=Station)
def update_station_status(
    station_id: int,
    status_update: StationStatusUpdate,
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_station_staff),
):
    try:
        station = service.update_station_status(station_id, status_update.status)
        if not station:
            raise HTTPException(status_code=404, detail="Station not found")
        return station
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{station_id}", status_code=204)
def delete_station(
    station_id: int,
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    existing_station = service.get_station(station_id)
    if not existing_station:
        raise HTTPException(status_code=404, detail="Station not found")

    service.delete_station(station_id)
