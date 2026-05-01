from fastapi import Depends

from app.application.services.charger_service import ChargerService
from app.application.services.charger_session_service import ChargingSessionService
from app.application.services.reservation_service import ReservationService
from app.application.services.station_service import StationService
from app.application.services.user_service import UserService
from app.application.services.vehicle_service import VehicleService
from app.core.uow import InMemoryUnitOfWork, AbstractUnitOfWork

# Simdilik global bir in-memory uow nesnesi olusturuyoruz.
_uow = InMemoryUnitOfWork()


def get_uow() -> AbstractUnitOfWork:
    return _uow


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
