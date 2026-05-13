from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.application.services.user_service import UserService
from app.core.dependencies import (
    get_current_company_member,
    get_user_service,
    get_current_user,
    AuthenticatedUser,
    get_admin,
    get_station_manager,
)
from app.application.services.company_member_service import CompanyMemberService
from app.core.dependencies import get_company_member_service

from app.domain.models.user import UserEntity
from app.schemas.user import UserCreate, User, UserLogin, AuthResponse
from app.schemas.company_member import CompanyEmployee
from app.schemas.vehicle import Vehicle
from app.schemas.reservation import Reservation
from app.schemas.charging_session import ChargingSession
from app.infrastructure.database.tables import CompanyMember as CompanyMemberModel
from app.infrastructure.database.database import get_db

from app.core.security import hash_password

router = APIRouter()

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
    auth_response = service.login_user(login_data.email, login_data.password)
    if not auth_response:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return auth_response


@router.get("/admin/all", response_model=List[User])
def get_users(service: UserService = Depends(get_user_service),
              current_user: AuthenticatedUser = Depends(get_admin)):
    return service.get_all_users()


@router.get("/my/company", response_model=List[CompanyEmployee])
def get_my_company_users(
    user_service: UserService = Depends(get_user_service),
    company_member_service: CompanyMemberService = Depends(get_company_member_service),
    member: CompanyMemberModel = Depends(get_current_company_member),
    current_user: AuthenticatedUser = Depends(get_station_manager),
):
    try:
        users = user_service.get_users_by_company(member.company_id)
        members = company_member_service.get_members_by_company(member.company_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    users_by_id = {user.id: user for user in users}
    return [
        {"member": company_member, "user": users_by_id[company_member.user_id]}
        for company_member in members
        if company_member.user_id in users_by_id
    ]

@router.patch("/me", status_code=204)
def delete_user(
    service: UserService = Depends(get_user_service),
    current_user: AuthenticatedUser = Depends(get_current_user)
):
    current_user_id = current_user.id
    user = service.get_user(current_user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    service.delete_user(current_user_id)

@router.get("/me", response_model=User)
def get_current_user_info(
    service: UserService = Depends(get_user_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user = service.get_user(current_user.id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    member = (
        db.query(CompanyMemberModel)
        .filter(
            CompanyMemberModel.user_id == current_user.id,
            CompanyMemberModel.is_active == True,
        )
        .first()
    )
    user_data = {
        "id": user.id,
        "name": user.name,
        "surname": user.surname,
        "email": user.email,
        "balance": user.balance,
        "role": user.role,
        "company_id": member.company_id if member else None,
        "membership_role": member.role if member else None,
    }
    return user_data

@router.patch("/admin/{user_id}", status_code=204)
def delete_user(
    user_id: int,
    service: UserService = Depends(get_user_service),
    current_user: AuthenticatedUser = Depends(get_admin)
):
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    service.delete_user(user_id)

@router.patch("/add_balance/me", response_model=User)
def add_balance(
    amount: float,
    service: UserService = Depends(get_user_service),
    current_user: AuthenticatedUser = Depends(get_current_user)
):
    try:
        return service.add_balance(current_user.id, amount)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
