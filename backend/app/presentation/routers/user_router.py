from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.user_service import UserService
from app.core.dependencies import get_user_service, get_current_user, AuthenticatedUser
from app.domain.models.user import UserEntity
from app.schemas.user import UserCreate, User, UserLogin, AuthResponse
from app.schemas.vehicle import Vehicle
from app.schemas.reservation import Reservation
from app.schemas.charging_session import ChargingSession

from app.core.security import hash_password

router = APIRouter()

def ensure_admin_role(
    current_user: AuthenticatedUser,
) -> None:
    if current_user.role.lower() != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")

def ensure_authenticated_user(
    user_id: int,
    current_user: AuthenticatedUser,
) -> None:
    if current_user.role.lower() != "admin" and current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not enough permissions")

@router.post("/", response_model=AuthResponse, status_code=201)
def create_user(
    user: UserCreate,
    service: UserService = Depends(get_user_service),
):
    try:
        user_data = user.model_dump()
        password = user_data.pop("password")
        existing_user = service.get_user_by_email(user_data["email"])
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        user_entity = UserEntity(
            **user_data,
            password_hash=hash_password(password)
        )
        return service.create_user(user_entity)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/login", response_model=AuthResponse)
def login_user(
    login_data: UserLogin,
    service: UserService = Depends(get_user_service),
):
    auth_response = service.login_user(login_data.mail, login_data.password)
    if not auth_response:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return auth_response


@router.get("/", response_model=List[User])
def get_users(service: UserService = Depends(get_user_service),
              current_user: AuthenticatedUser = Depends(get_current_user)):
    ensure_admin_role(user_id=None, current_user=current_user)
    return service.get_all_users()


@router.get("/{user_id}", response_model=User)
def get_user(
    user_id: int,
    service: UserService = Depends(get_user_service),
    current_user: AuthenticatedUser = Depends(get_current_user)
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_authenticated_user(user_id, current_user)
    return user

@router.get("/{user_id}/vehicles", response_model=List[Vehicle])
def get_user_vehicles(
    user_id: int,
    service: UserService = Depends(get_user_service),
    current_user: AuthenticatedUser = Depends(get_current_user)
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_authenticated_user(user_id, current_user)
    return service.get_user_vehicles(user_id)


@router.get("/{user_id}/reservations", response_model=List[Reservation])
def get_user_reservations(
    user_id: int,
    service: UserService = Depends(get_user_service),
    current_user: AuthenticatedUser = Depends(get_current_user)
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_authenticated_user(user_id, current_user)
    return service.get_user_reservations(user_id)

@router.get("/{user_id}/charging_sessions", response_model=List[ChargingSession])
def get_user_charging_sessions(
    user_id: int,
    service: UserService = Depends(get_user_service),
    current_user: AuthenticatedUser = Depends(get_current_user)
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_authenticated_user(user_id, current_user)
    return service.get_user_charging_sessions(user_id)

@router.delete("/{user_id}", status_code=204)
def delete_user(
    user_id: int,
    service: UserService = Depends(get_user_service),
    current_user: AuthenticatedUser = Depends(get_current_user)
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_authenticated_user(user_id, current_user)
    service.delete_user(user_id)