from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.vehicle_service import VehicleService
from app.core.dependencies import AuthenticatedUser, get_current_user, get_vehicle_service
from app.domain.models.vehicle import VehicleEntity
from app.schemas.charger import Charger
from app.schemas.vehicle import VehicleCreate, Vehicle

router = APIRouter()


def ensure_vehicle_owner_or_admin(
    vehicle: VehicleEntity,
    current_user: AuthenticatedUser,
) -> None:
    if vehicle.user_id != current_user.id and current_user.role.lower() != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")


@router.post("/", response_model=Vehicle, status_code=201)
def create_vehicle(
    vehicle: VehicleCreate,
    service: VehicleService = Depends(get_vehicle_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    vehicle_entity = VehicleEntity(user_id=current_user.id, **vehicle.model_dump())
    try:
        return service.create_vehicle(vehicle_entity, current_user.id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/", response_model=List[Vehicle])
def get_vehicles(
    service: VehicleService = Depends(get_vehicle_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    if current_user.role.lower() != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return service.get_all_vehicles()


@router.get("/{vehicle_id}/compatible-chargers", response_model=List[Charger])
def get_compatible_chargers(
    vehicle_id: int,
    service: VehicleService = Depends(get_vehicle_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    vehicle = service.get_vehicle(vehicle_id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    ensure_vehicle_owner_or_admin(vehicle, current_user)
    return service.get_compatible_chargers(vehicle_id)


@router.get("/{vehicle_id}", response_model=Vehicle)
def get_vehicle(
    vehicle_id: int,
    service: VehicleService = Depends(get_vehicle_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    vehicle = service.get_vehicle(vehicle_id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    ensure_vehicle_owner_or_admin(vehicle, current_user)
    return vehicle


@router.delete("/{vehicle_id}", status_code=204)
def delete_vehicle(
    vehicle_id: int,
    service: VehicleService = Depends(get_vehicle_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    vehicle = service.get_vehicle(vehicle_id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    ensure_vehicle_owner_or_admin(vehicle, current_user)
    service.delete_vehicle(vehicle_id)


@router.put("/{vehicle_id}", response_model=Vehicle)
def update_vehicle(
    vehicle_id: int,
    vehicle: VehicleCreate,
    service: VehicleService = Depends(get_vehicle_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    existing_vehicle = service.get_vehicle(vehicle_id)
    if not existing_vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    ensure_vehicle_owner_or_admin(existing_vehicle, current_user)

    updated_vehicle = VehicleEntity(
        id=vehicle_id,
        user_id=existing_vehicle.user_id,
        is_active=existing_vehicle.is_active,
        **vehicle.model_dump(),
    )
    try:
        return service.update_vehicle(updated_vehicle)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
