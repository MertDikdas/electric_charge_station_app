from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.vehicle_service import VehicleService
from app.core.dependencies import get_vehicle_service
from app.domain.models.vehicle import VehicleEntity
from app.schemas.vehicle import VehicleCreate, Vehicle

router = APIRouter()


@router.post("/", response_model=Vehicle, status_code=201)
def create_vehicle(
    vehicle: VehicleCreate,
    service: VehicleService = Depends(get_vehicle_service),
):
    vehicle_entity = VehicleEntity(**vehicle.model_dump())
    return service.create_vehicle(vehicle_entity)


@router.get("/", response_model=List[Vehicle])
def get_vehicles(service: VehicleService = Depends(get_vehicle_service)):
    return service.get_all_vehicles()


@router.get("/{vehicle_id}", response_model=Vehicle)
def get_vehicle(
    vehicle_id: int,
    service: VehicleService = Depends(get_vehicle_service),
):
    vehicle = service.get_vehicle(vehicle_id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return vehicle

@router.delete("/{vehicle_id}", status_code=204)
def delete_vehicle(
    vehicle_id: int,
    service: VehicleService = Depends(get_vehicle_service),
):
    service.delete_vehicle(vehicle_id)

@router.put("/{vehicle_id}", response_model=Vehicle)
def update_vehicle(
    vehicle_id: int,
    vehicle: VehicleCreate,
    service: VehicleService = Depends(get_vehicle_service),
):
    existing_vehicle = service.get_vehicle(vehicle_id)
    if not existing_vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    
    updated_vehicle = VehicleEntity(id=vehicle_id, **vehicle.model_dump())
    return service.update_vehicle(updated_vehicle)