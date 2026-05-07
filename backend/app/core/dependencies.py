from dataclasses import dataclass
from datetime import datetime
from typing import Optional

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.application.services.charger_service import ChargerService
from app.application.services.charger_session_service import ChargingSessionService
from app.application.services.coupon_service import CouponService
from app.application.services.notification_service import NotificationService
from app.application.services.payment_service import PaymentService
from app.application.services.reservation_service import ReservationService
from app.application.services.station_service import StationService
from app.application.services.user_service import UserService
from app.application.services.vehicle_service import VehicleService
from app.core.security import ALGORITHM, SECRET_KEY
from app.core.uow import AbstractUnitOfWork, SqlAlchemyUnitOfWork
from app.infrastructure.database.database import get_db
from app.infrastructure.repositories.sqlalchemy.user_session_repository import (
    SqlAlchemyUserSessionRepository,
)
from app.infrastructure.repositories.sqlalchemy.user_repository import SqlAlchemyUserRepository

security = HTTPBearer(auto_error=False)

USER_ROLE = "USER"
STATION_MANAGER_ROLE = "STATION_MANAGER"
STATION_OPERATOR_ROLE = "STATION_OPERATOR"
ADMIN_ROLE = "ADMIN"


@dataclass
class AuthenticatedUser:
    id: int
    role: str = USER_ROLE

    @property
    def is_staff(self) -> bool:
        return self.role in {ADMIN_ROLE, STATION_MANAGER_ROLE, STATION_OPERATOR_ROLE}


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db),
) -> AuthenticatedUser:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Authentication required")

    if credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Invalid authentication header")

    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    try:
        token_user_id = int(payload.get("user_id"))
    except (TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid token payload")

    session = SqlAlchemyUserSessionRepository(db).get_by_token(token)
    if session is None or session.is_revoked or session.expires_at <= datetime.utcnow():
        raise HTTPException(status_code=401, detail="Invalid or expired session")

    if session.user_id != token_user_id:
        raise HTTPException(status_code=401, detail="Token does not match session")

    user = SqlAlchemyUserRepository(db).get(session.user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")

    return AuthenticatedUser(id=session.user_id, role=user.role or USER_ROLE)


def get_admin_or_station_manager(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    if current_user.role not in {ADMIN_ROLE, STATION_MANAGER_ROLE}:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return current_user


def get_station_manager(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    if current_user.role not in {ADMIN_ROLE, STATION_MANAGER_ROLE}:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return current_user


def get_only_station_manager(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    if current_user.role != STATION_MANAGER_ROLE:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return current_user


def get_station_staff(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    if current_user.role not in {
        ADMIN_ROLE,
        STATION_MANAGER_ROLE,
        STATION_OPERATOR_ROLE,
    }:
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


def get_notification_service(
    uow: AbstractUnitOfWork = Depends(get_uow),
) -> NotificationService:
    return NotificationService(uow)


def get_coupon_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> CouponService:
    return CouponService(uow)


def get_payment_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> PaymentService:
    return PaymentService(uow)
