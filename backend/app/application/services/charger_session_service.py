from datetime import date, datetime, time
from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.charging_session import ChargingSessionEntity
from app.domain.models.notification import NotificationEntity
from app.domain.models.payment import PaymentEntity
from app.domain.rules.charger_rules import can_start_charging_session
from app.domain.rules.charging_session_rules import validate_can_start_charging_session

ACTIVE_RESERVATION_STATUSES = {"PENDING", "CONFIRMED"}
RUNNING_SESSION_STATUSES = {"STARTED", "IN_PROGRESS"}


class ChargingSessionService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_session(self, session: ChargingSessionEntity) -> ChargingSessionEntity:
        with self.uow:
            reservation = self.uow.reservations.get(session.reservation_id)
            if not reservation:
                raise LookupError("Reservation not found")

            vehicle = self.uow.vehicles.get(reservation.vehicle_id)
            if not vehicle:
                raise LookupError("Vehicle not found")

            charger = self.uow.chargers.get(reservation.charger_id)
            if not charger:
                raise LookupError("Charger not found")

            validate_can_start_charging_session(
                charger=charger,
                vehicle=vehicle,
                active_reservations=reservation,
                active_charging_sessions=self.uow.charging_sessions.list_active_by_charger_id(
                    charger.id
                ),
            )
            new_session = self.uow.charging_sessions.add(session)
            self.uow.commit()
            return new_session

    def get_all_sessions(self) -> List[ChargingSessionEntity]:
        with self.uow:
            return self.uow.charging_sessions.list()

    def get_session(self, session_id: int) -> Optional[ChargingSessionEntity]:
        with self.uow:
            return self.uow.charging_sessions.get(session_id)

    def get_user_sessions(self, user_id: int) -> List[ChargingSessionEntity]:
        with self.uow:
            return self.uow.charging_sessions.list_by_user_id(user_id)

    def get_active_sessions_by_user_id(self, user_id: int) -> List[ChargingSessionEntity]:
        with self.uow:
            return self.uow.charging_sessions.list_active_by_user_id(user_id)

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
        reservation_id: Optional[int],
        current_user_id: int,
        is_staff: bool = False,
    ) -> ChargingSessionEntity:
        with self.uow:
            now = datetime.now()
            if reservation_id is None:
                reservation = self._find_current_active_reservation(current_user_id, now)
                reservation_id = reservation.id
            else:
                reservation = self.uow.reservations.get(reservation_id)
                if not reservation:
                    raise LookupError("Reservation not found")

            if reservation.user_id != current_user_id and not is_staff:
                raise PermissionError("Not enough permissions")

            if reservation.status not in ACTIVE_RESERVATION_STATUSES:
                raise ValueError("Reservation is not active")

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
        session_id: Optional[int],
        current_user_id: int,
        is_staff: bool = False,
        end_time: Optional[time] = None,
    ) -> ChargingSessionEntity:
        with self.uow:
            if session_id is None:
                session = self._find_current_active_session(current_user_id)
                session_id = session.id
            else:
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

            finish_time = self._normalize_time(
                (end_time or datetime.now().time()).replace(microsecond=0)
            )
            session_start_time = self._normalize_time(session.start_time)
            reservation_end_time = self._normalize_time(reservation.end_time)

            if finish_time <= session_start_time:
                raise ValueError("Session finish time must be after start time")
            if finish_time > reservation_end_time:
                raise ValueError("Session finish time cannot be after reservation end time")

            consumed_energy = self._calculate_consumed_energy(
                session_start_time,
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

            self._create_pending_payment_for_finished_session(
                reservation_user_id=reservation.user_id,
                reservation_id=session.reservation_id,
                amount=session.cost,
            )
            self._create_session_finished_notification(
                reservation_user_id=reservation.user_id,
                reservation_id=session.reservation_id,
                amount=session.cost,
            )

            self.uow.commit()
            return finished_session

    def _create_pending_payment_for_finished_session(
        self,
        reservation_user_id: int,
        reservation_id: int,
        amount: float,
    ) -> None:
        existing_payment = self.uow.payments.get_by_reservation_id(reservation_id)
        if existing_payment:
            return

        if amount <= 0:
            return

        self.uow.payments.add(
            PaymentEntity(
                user_id=reservation_user_id,
                reservation_id=reservation_id,
                amount=amount,
                status="PENDING",
            )
        )

    def _create_session_finished_notification(
        self,
        reservation_user_id: int,
        reservation_id: int,
        amount: float,
    ) -> None:
        title = "Charging session completed"
        message = (
            f"Your charging session for reservation {reservation_id} has been completed. "
            f"Payment amount: {amount:.2f}."
        )

        if self.uow.notifications.exists_by_user_and_title_and_message(
            reservation_user_id,
            title,
            message,
        ):
            return

        self.uow.notifications.add(
            NotificationEntity(
                user_id=reservation_user_id,
                title=title,
                message=message,
                notification_type="SUCCESS",
            )
        )

    def _find_current_active_reservation(
        self,
        user_id: int,
        current_datetime: datetime,
    ):
        reservations = self.uow.reservations.list_by_user_and_date(
            user_id, current_datetime.date()
        )
        active_reservations = [
            reservation
            for reservation in reservations
            if self._is_reservation_time_active(reservation, current_datetime)
        ]

        if not active_reservations:
            raise ValueError("No active reservation found for current time")
        if len(active_reservations) > 1:
            raise ValueError("Multiple active reservations found for current time")

        return active_reservations[0]

    def _find_current_active_session(self, current_user_id: int) -> ChargingSessionEntity:
        active_sessions = self.uow.charging_sessions.list_active_by_user_id(
            current_user_id
        )

        if not active_sessions:
            raise LookupError("No active charging session found")
        if len(active_sessions) > 1:
            raise ValueError("Multiple active charging sessions found")

        return active_sessions[0]

    def _normalize_time(self, value: time) -> time:
        return value.replace(tzinfo=None) if value.tzinfo is not None else value

    def _is_reservation_time_active(self, reservation, current_datetime: datetime) -> bool:
        current_time = self._normalize_time(current_datetime.time())
        return (
            reservation.date == current_datetime.date()
            and self._normalize_time(reservation.start_time) <= current_time
            and self._normalize_time(reservation.end_time) >= current_time
        )

    def _calculate_consumed_energy(
        self,
        start_time: time,
        end_time: time,
        charging_power_kw: float,
    ) -> float:
        start_time = self._normalize_time(start_time)
        end_time = self._normalize_time(end_time)
        start_datetime = datetime.combine(date.today(), start_time)
        end_datetime = datetime.combine(date.today(), end_time)
        duration_hours = (end_datetime - start_datetime).total_seconds() / 3600
        return round(duration_hours * charging_power_kw, 3)
    
    
    def get_active_session_progress(
        self,
        current_user_id: int,
        is_staff: bool = False,
    ):
        with self.uow:
            sessions = self.uow.charging_sessions.list()

            active_session = None
            active_reservation = None

            for session in sessions:
                if session.status not in RUNNING_SESSION_STATUSES:
                    continue

                reservation = self.uow.reservations.get(session.reservation_id)
                if not reservation:
                    continue

                if reservation.user_id == current_user_id or is_staff:
                    active_session = session
                    active_reservation = reservation
                    break

            if not active_session or not active_reservation:
                return None

            charger = self.uow.chargers.get(active_reservation.charger_id)
            vehicle = self.uow.vehicles.get(active_reservation.vehicle_id)

            if not charger or not vehicle:
                raise LookupError("Charger or vehicle not found")

            now = datetime.now()
            current_time = now.time().replace(microsecond=0)

            charging_power_kw = min(vehicle.max_charging_power, charger.max_power)

            estimated_energy = self._calculate_consumed_energy(
                active_session.start_time,
                current_time,
                charging_power_kw,
            )

            estimated_cost = round(estimated_energy * charger.price_per_kwh, 2)

            session_start_dt = datetime.combine(date.today(), self._normalize_time(active_session.start_time))
            now_dt = datetime.combine(date.today(), self._normalize_time(current_time))
            elapsed_seconds = max((now_dt - session_start_dt).total_seconds(), 0)

            battery_capacity = getattr(vehicle, "battery_capacity", None)
            if battery_capacity is None:
                battery_capacity = getattr(vehicle, "battery_capacity_kwh", None)

            if battery_capacity and battery_capacity > 0:
                progress_percent = min((estimated_energy / battery_capacity) * 100, 100)
            else:
                progress_percent = 0
            return {
                "session_id": active_session.id,
                "reservation_id": active_session.reservation_id,
                "status": active_session.status,
                "elapsed_minutes": int(elapsed_seconds // 60),
                "estimated_energy_kwh": round(estimated_energy, 2),
                "estimated_cost": estimated_cost,
                "progress_percent": round(progress_percent, 1),
            }
