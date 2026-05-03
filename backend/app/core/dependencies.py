from dataclasses import dataclass
from typing import Optional

from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.application.services.charger_service import ChargerService
from app.application.services.charger_session_service import ChargingSessionService
from app.application.services.reservation_service import ReservationService
from app.application.services.station_service import StationService
from app.application.services.user_service import UserService
from app.application.services.vehicle_service import VehicleService
from app.core.uow import AbstractUnitOfWork, SqlAlchemyUnitOfWork
from app.infrastructure.database.database import get_db


@dataclass
class AuthenticatedUser:
    id: int
    role: str = "user"

    @property
    def is_staff(self) -> bool:
        return self.role.lower() in {"admin", "station_manager", "staff"}


def get_current_user(
    x_user_id: Optional[int] = Header(default=None),
    x_user_role: str = Header(default="user"),
) -> AuthenticatedUser:
    if x_user_id is None:
        raise HTTPException(status_code=401, detail="Authentication required")
    return AuthenticatedUser(id=x_user_id, role=x_user_role)


def get_admin_or_station_manager(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    if current_user.role.lower() not in {"admin", "station_manager"}:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return current_user


def get_uow(db: Session = Depends(get_db)) -> AbstractUnitOfWork:
    return SqlAlchemyUnitOfWork(db)


def get_user_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> UserService:
    return UserService(uow)


def get_vehicle_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> VehicleService:
    return VehicleService(uow)


def get_station_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> StationService:
    return StationService(uow)


def get_charger_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> ChargerService:
    return ChargerService(uow)


def get_reservation_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> ReservationService:
    return ReservationService(uow)


def get_charging_session_service(
    uow: AbstractUnitOfWork = Depends(get_uow),
) -> ChargingSessionService:
    return ChargingSessionService(uow)
