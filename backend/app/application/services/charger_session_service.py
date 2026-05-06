from datetime import date, datetime, time
from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.charging_session import ChargingSessionEntity
from app.domain.rules.charger_rules import can_start_charging_session


ACTIVE_RESERVATION_STATUSES = {"PENDING", "CONFIRMED"}
RUNNING_SESSION_STATUSES = {"STARTED", "IN_PROGRESS"}


class ChargingSessionService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_session(self, session: ChargingSessionEntity) -> ChargingSessionEntity:
        with self.uow:
            new_session = self.uow.charging_sessions.add(session)
            self.uow.commit()
            return new_session

    def get_all_sessions(self) -> List[ChargingSessionEntity]:
        with self.uow:
            return self.uow.charging_sessions.list()

    def get_session(self, session_id: int) -> Optional[ChargingSessionEntity]:
        with self.uow:
            return self.uow.charging_sessions.get(session_id)

    def can_access_session(
        self,
        session: ChargingSessionEntity,
        current_user_id: int,
        is_staff: bool = False,
    ) -> bool:
        with self.uow:
            reservation = self.uow.reservations.get(session.reservation_id)
            if not reservation:
                return False
            return reservation.user_id == current_user_id or is_staff

    def start_session(
        self,
        reservation_id: int,
        current_user_id: int,
        is_staff: bool = False,
    ) -> ChargingSessionEntity:
        with self.uow:
            reservation = self.uow.reservations.get(reservation_id)
            if not reservation:
                raise LookupError("Reservation not found")

            if reservation.user_id != current_user_id and not is_staff:
                raise PermissionError("Not enough permissions")

            if reservation.status not in ACTIVE_RESERVATION_STATUSES:
                raise ValueError("Reservation is not active")

            now = datetime.now()
            if not self._is_reservation_time_active(reservation, now):
                raise ValueError("Reservation is not active")

            existing_session = self.uow.charging_sessions.get_by_reservation_id(
                reservation_id
            )
            if existing_session:
                raise ValueError("Charging session already exists for this reservation")

            vehicle = self.uow.vehicles.get(reservation.vehicle_id)
            if not vehicle:
                raise LookupError("Vehicle not found")

            charger = self.uow.chargers.get(reservation.charger_id)
            if not charger:
                raise LookupError("Charger not found")

            if not can_start_charging_session(charger, vehicle):
                raise ValueError("Charger is not available or vehicle is incompatible")

            session = ChargingSessionEntity(
                reservation_id=reservation_id,
                start_time=now.time().replace(microsecond=0),
                status="IN_PROGRESS",
            )
            new_session = self.uow.charging_sessions.add(session)

            charger.status = "OCCUPIED"
            self.uow.chargers.update(charger)

            reservation.status = "CONFIRMED"
            self.uow.reservations.update(reservation)

            self.uow.commit()
            return new_session

    def finish_session(
        self,
        session_id: int,
        current_user_id: int,
        is_staff: bool = False,
        end_time: Optional[time] = None,
    ) -> ChargingSessionEntity:
        with self.uow:
            session = self.uow.charging_sessions.get(session_id)
            if not session:
                raise LookupError("Charging session not found")

            if session.status not in RUNNING_SESSION_STATUSES:
                raise ValueError("Charging session is not in progress")

            reservation = self.uow.reservations.get(session.reservation_id)
            if not reservation:
                raise LookupError("Reservation not found")

            if reservation.user_id != current_user_id and not is_staff:
                raise PermissionError("Not enough permissions")

            charger = self.uow.chargers.get(reservation.charger_id)
            if not charger:
                raise LookupError("Charger not found")

            vehicle = self.uow.vehicles.get(reservation.vehicle_id)
            if not vehicle:
                raise LookupError("Vehicle not found")

            finish_time = (end_time or datetime.now().time()).replace(microsecond=0)
            if finish_time <= session.start_time:
                raise ValueError("Session finish time must be after start time")

            consumed_energy = self._calculate_consumed_energy(
                session.start_time,
                finish_time,
                min(vehicle.max_charging_power, charger.max_power),
            )
            session.end_time = finish_time
            session.consuming_power = consumed_energy
            session.cost = round(consumed_energy * charger.price_per_kwh, 2)
            session.status = "COMPLETED"
            finished_session = self.uow.charging_sessions.update(session)

            charger.status = "AVAILABLE"
            self.uow.chargers.update(charger)

            reservation.status = "COMPLETED"
            self.uow.reservations.update(reservation)

            self.uow.commit()
            return finished_session

    def _is_reservation_time_active(self, reservation, current_datetime: datetime) -> bool:
        return (
            reservation.date == current_datetime.date()
            and reservation.start_time <= current_datetime.time()
            and reservation.end_time >= current_datetime.time()
        )

    def _calculate_consumed_energy(
        self,
        start_time: time,
        end_time: time,
        charging_power_kw: float,
    ) -> float:
        start_datetime = datetime.combine(date.today(), start_time)
        end_datetime = datetime.combine(date.today(), end_time)
        duration_hours = (end_datetime - start_datetime).total_seconds() / 3600
        return round(duration_hours * charging_power_kw, 3)
