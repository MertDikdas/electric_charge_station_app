from abc import ABC, abstractmethod

from sqlalchemy.orm import Session

from app.infrastructure.repositories import (
    AbstractChargerRepository,
    AbstractChargingSessionRepository,
    AbstractCouponRepository,
    AbstractNotificationRepository,
    AbstractPaymentRepository,
    AbstractReservationRepository,
    AbstractStationRepository,
    AbstractUserRepository,
    AbstractVehicleRepository,
    SqlAlchemyChargerRepository,
    SqlAlchemyChargingSessionRepository,
    SqlAlchemyCouponRepository,
    SqlAlchemyNotificationRepository,
    SqlAlchemyPaymentRepository,
    SqlAlchemyReservationRepository,
    SqlAlchemyStationRepository,
    SqlAlchemyUserRepository,
    SqlAlchemyVehicleRepository,
)

class AbstractUnitOfWork(ABC):
    users: AbstractUserRepository
    vehicles: AbstractVehicleRepository
    stations: AbstractStationRepository
    chargers: AbstractChargerRepository
    reservations: AbstractReservationRepository
    charging_sessions: AbstractChargingSessionRepository
    notifications: AbstractNotificationRepository
    coupons: AbstractCouponRepository
    payments: AbstractPaymentRepository

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            self.rollback()
        else:
            self.commit()

    @abstractmethod
    def commit(self):
        raise NotImplementedError

    @abstractmethod
    def rollback(self):
        raise NotImplementedError


class SqlAlchemyUnitOfWork(AbstractUnitOfWork):
    def __init__(self, session: Session):
        self.session = session
        self.users = SqlAlchemyUserRepository(session)
        self.vehicles = SqlAlchemyVehicleRepository(session)
        self.stations = SqlAlchemyStationRepository(session)
        self.chargers = SqlAlchemyChargerRepository(session)
        self.reservations = SqlAlchemyReservationRepository(session)
        self.charging_sessions = SqlAlchemyChargingSessionRepository(session)
        self.notifications = SqlAlchemyNotificationRepository(session)
        self.coupons = SqlAlchemyCouponRepository(session)
        self.payments = SqlAlchemyPaymentRepository(session)

    def commit(self):
        self.session.commit()

    def rollback(self):
        self.session.rollback()
