from dataclasses import dataclass
from datetime import datetime
from typing import Optional

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.application.services.charger_service import ChargerService
from app.application.services.charger_session_service import ChargingSessionService
from app.application.services.company_member_service import CompanyMemberService
from app.application.services.coupon_service import CouponService
from app.application.services.notification_service import NotificationService
from app.application.services.payment_service import PaymentService
from app.application.services.reservation_service import ReservationService
from app.application.services.station_service import StationService
from app.application.services.user_service import UserService
from app.application.services.vehicle_service import VehicleService
from app.application.services.chatbot_service import ChatbotService
from app.application.services.station_service import StationService
from app.core.security import ALGORITHM, SECRET_KEY
from app.core.uow import AbstractUnitOfWork, SqlAlchemyUnitOfWork
from app.infrastructure.database.database import get_db
from app.infrastructure.repositories.sqlalchemy.user_session_repository import (
    SqlAlchemyUserSessionRepository,
)
from app.infrastructure.repositories.sqlalchemy.user_repository import SqlAlchemyUserRepository
from app.schemas.company_member import CompanyMember
from datetime import datetime
from zoneinfo import ZoneInfo
from app.infrastructure.database.tables import Charger, CompanyMember, Station
from app.application.services.company_service import CompanyService

security = HTTPBearer(auto_error=False)

USER_ROLE = "USER"
COMPANY_MANAGER_ROLE = "COMPANY_MANAGER"
COMPANY_OPERATOR_ROLE = "COMPANY_OPERATOR"
STATION_MANAGER_ROLE = "STATION_MANAGER"
STATION_OPERATOR_ROLE = "STATION_OPERATOR"
ADMIN_ROLE = "ADMIN"
MANAGER_ROLES = {COMPANY_MANAGER_ROLE, STATION_MANAGER_ROLE}
OPERATOR_ROLES = {COMPANY_OPERATOR_ROLE, STATION_OPERATOR_ROLE}
COMPANY_STAFF_ROLES = MANAGER_ROLES | OPERATOR_ROLES

TURKEY_TZ = ZoneInfo("Europe/Istanbul")



def now_in_turkey() -> datetime:
    return datetime.now(TURKEY_TZ)


@dataclass
class AuthenticatedUser:
    id: int
    role: str = USER_ROLE

    @property
    def is_staff(self) -> bool:
        return self.role in {ADMIN_ROLE, *COMPANY_STAFF_ROLES}


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
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Inactive account")

    return AuthenticatedUser(id=session.user_id, role=user.role or USER_ROLE)

def get_current_company_member(
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CompanyMember:
    member = (
        db.query(CompanyMember)
        .filter(
            CompanyMember.user_id == current_user.id,
            CompanyMember.is_active == True,
        )
        .first()
    )

    if member is None:
        raise HTTPException(status_code=403, detail="Company membership required")

    return member

def get_admin(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    if current_user.role != ADMIN_ROLE:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return current_user


def get_station_manager(
    member: CompanyMember = Depends(get_current_company_member),
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    if current_user.role != ADMIN_ROLE and member.role not in MANAGER_ROLES:
        raise HTTPException(status_code=403, detail="Company manager role required")
    return current_user



def get_station_operator(
    member: CompanyMember = Depends(get_current_company_member),
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    if current_user.role != ADMIN_ROLE and member.role not in COMPANY_STAFF_ROLES:
        raise HTTPException(status_code=403, detail="Company operator role required")
    return current_user

def get_company_member(
    member: CompanyMember = Depends(get_current_company_member),
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    if current_user.role != ADMIN_ROLE and member.role not in COMPANY_STAFF_ROLES:
        raise HTTPException(status_code=403, detail="Company staff role required")
    return current_user

def ensure_same_company(
    station_id: int,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    station = ( db.query(Station).filter(Station.id == station_id).first() )
    if station is None:
        raise HTTPException(status_code=404, detail="Station not found")
    member = (
        db.query(CompanyMember).filter(CompanyMember.company_id == station.company_id, CompanyMember.user_id == current_user.id, CompanyMember.is_active == True).first())
    if member is None:
        raise HTTPException(status_code=403, detail="Company membership required")
    return member

def ensure_same_company_for_charger(
    charger_id: int,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CompanyMember:
    charger = ( db.query(Charger).filter(Charger.id == charger_id).first() )
    if charger is None:
        raise HTTPException(status_code=404, detail="Charger not found")
    station = ( db.query(Station).filter(Station.id == charger.station_id).first() )
    if station is None:
        raise HTTPException(status_code=404, detail="Station not found")
    member = (
        db.query(CompanyMember).filter(CompanyMember.company_id == station.company_id, CompanyMember.user_id == current_user.id, CompanyMember.is_active == True).first())
    if member is None:
        raise HTTPException(status_code=403, detail="Company membership required")
    return member


def get_uow(db: Session = Depends(get_db)) -> AbstractUnitOfWork:
    return SqlAlchemyUnitOfWork(db)


def get_user_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> UserService:
    return UserService(uow)

def get_statistics_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> StationService:
    return StationService(uow)

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

def get_chatbot_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> ChatbotService:
    return ChatbotService(uow)

def get_company_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> CompanyService:
    return CompanyService(uow)

def get_company_member_service(uow: AbstractUnitOfWork = Depends(get_uow)) -> CompanyMemberService:
    return CompanyMemberService(uow)

