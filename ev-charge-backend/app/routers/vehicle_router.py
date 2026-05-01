from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.models.vehicle import VehicleCreate, Vehicle
from app.core.uow import AbstractUnitOfWork
from app.core.dependencies import get_uow

router = APIRouter()

@router.post("/", response_model=Vehicle, status_code=201)
def create_vehicle(vehicle: VehicleCreate, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        # id değerini 0 veriyoruz, repository eklendiğinde gerçek id'yi verecek
        new_vehicle = Vehicle(**vehicle.model_dump(), id=0)
        uow.vehicles.add(new_vehicle)
        uow.commit()
        return new_vehicle

@router.get("/", response_model=List[Vehicle])
def get_vehicles(uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        return uow.vehicles.list()

@router.get("/{vehicle_id}", response_model=Vehicle)
def get_vehicle(vehicle_id: int, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        vehicle = uow.vehicles.get(vehicle_id)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        return vehicle