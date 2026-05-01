from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.user_service import UserService
from app.core.dependencies import get_user_service
from app.domain.models.user import UserCreate, User

router = APIRouter()


@router.post("/", response_model=User, status_code=201)
def create_user(
    user: UserCreate,
    service: UserService = Depends(get_user_service),
):
    return service.create_user(user)


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
