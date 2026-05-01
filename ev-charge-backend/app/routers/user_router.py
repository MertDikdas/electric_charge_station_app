from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.models.user import UserCreate, User
from app.core.uow import AbstractUnitOfWork
from app.core.dependencies import get_uow

router = APIRouter()

@router.post("/", response_model=User, status_code=201)
def create_user(user: UserCreate, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        new_user = User(**user.model_dump(), id=0)
        uow.users.add(new_user)
        uow.commit()
        return new_user

@router.get("/", response_model=List[User])
def get_users(uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        return uow.users.list()

@router.get("/{user_id}", response_model=User)
def get_user(user_id: int, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        user = uow.users.get(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
