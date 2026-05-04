from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.user_service import UserService
from app.core.dependencies import get_user_service
from app.domain.models.user import UserEntity
from app.schemas.user import UserCreate, User
from app.schemas.vehicle import Vehicle
from app.schemas.reservation import Reservation
from app.schemas.charging_session import ChargingSession

from app.core.security import hash_password

router = APIRouter()


@router.post("/", response_model=User, status_code=201)
def create_user(
    user: UserCreate,
    service: UserService = Depends(get_user_service),
):
    user_data = user.model_dump()
    password = user_data.pop("password")

    user_entity = UserEntity(
        **user_data,
        password_hash=hash_password(password)
    )
    return service.create_user(user_entity)


@router.get("/", response_model=List[User])
def get_users(service: UserService = Depends(get_user_service)):
    return service.get_all_users()


@router.get("/{user_id}", response_model=User)
def get_user(
    user_id: int,
    service: UserService = Depends(get_user_service),
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/{user_id}/vehicles", response_model=List[Vehicle])
def get_user_vehicles(
    user_id: int,
    service: UserService = Depends(get_user_service),
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return service.get_user_vehicles(user_id)


@router.get("/{user_id}/reservations", response_model=List[Reservation])
def get_user_reservations(
    user_id: int,
    service: UserService = Depends(get_user_service),
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return service.get_user_reservations(user_id)

@router.get("/{user_id}/charging_sessions", response_model=List[ChargingSession])
def get_user_charging_sessions(
    user_id: int,
    service: UserService = Depends(get_user_service),
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return service.get_user_charging_sessions(user_id)

@router.delete("/{user_id}", status_code=204)
def delete_user(
    user_id: int,
    service: UserService = Depends(get_user_service),
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    service.delete_user(user_id)