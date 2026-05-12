from typing import List, Optional
from datetime import date, datetime, timedelta

from app.core.uow import AbstractUnitOfWork
from app.domain.models.reservation import ReservationEntity
from app.domain.rules.reservation_rules import (
    ensure_reservation_not_in_past,
    ensure_reservation_not_too_far_in_future,
    validate_reservation_conflicts,
    validate_reservation_duration,
    validate_reservation_time,
    validate_reservation_status,
    validate_charger_id,
    validate_vehicle_id,
    validate_compatibility,
    validate_user_reservation_conflicts,
    validate_reservation_slot_interval,
    calculate_end_time,
)

DURATION_MINUTES = 120


class ReservationConflictError(ValueError):
    pass

class ReservationService:
    allowed_statuses = {"PENDING", "CONFIRMED"}

    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_reservation(
        self,
        reservation: ReservationEntity,
        current_user_id: int,
    ) -> ReservationEntity:
        with self.uow:
            reservation.user_id = current_user_id
            reservation.status = reservation.status.upper()
            reservation.duration_minutes = DURATION_MINUTES
            start_at = datetime.combine(reservation.date, reservation.start_time)
            end_at = start_at + timedelta(minutes=DURATION_MINUTES)
            if end_at.date() != reservation.date:
                raise ValueError("Reservation must end on the same day")
            reservation.end_time = end_at.time()
            self._validate_reservation_request(reservation)

            new_reservation = self.uow.reservations.add(reservation)
            self.uow.commit()
            return new_reservation

    def get_all_reservations(self) -> List[ReservationEntity]:
        with self.uow:
            return self.uow.reservations.list()

    def get_user_reservations(self, user_id: int) -> List[ReservationEntity]:
        with self.uow:
            user = self.uow.users.get(user_id)
            if not user:
                raise LookupError("User not found")
            return self.uow.reservations.list_by_user_id(user_id)

    def get_reservation(self, reservation_id: int) -> Optional[ReservationEntity]:
        with self.uow:
            return self.uow.reservations.get(reservation_id)

    def delete_reservation(self, reservation_id: int) -> bool:
        with self.uow:
            reservation = self.uow.reservations.get(reservation_id)
            if not reservation:
                return False
            self.uow.reservations.delete(reservation)
            self.uow.commit()
            return True

    def get_reservations_by_charger_and_date(
        self, charger_id: int, reservation_date: date
    ) -> List[ReservationEntity]:
        with self.uow:
            return self.uow.reservations.list_by_charger_and_date(
                charger_id, reservation_date
            )

    def _validate_reservation_request(self, reservation: ReservationEntity) -> None:
        validate_reservation_time(reservation)
        validate_reservation_slot_interval(reservation)
        validate_reservation_status(reservation)

        ensure_reservation_not_in_past(reservation)
        ensure_reservation_not_too_far_in_future(reservation)
        validate_reservation_duration(reservation, expected_minutes=DURATION_MINUTES)
        
        user = self.uow.users.get(reservation.user_id)
        if not user:
            raise LookupError("User not found")

        bad_reservations_count = self.uow.reservations.get_expired_or_cancelled_count_last_2_months(
            reservation.user_id
        )
        if bad_reservations_count >= 3:
            raise ValueError(
                "User has 3 or more expired or cancelled reservations in the last 2 months and cannot make a new reservation"
            )

        same_day_reservations = self.uow.reservations.list_by_user_and_date(
            reservation.user_id,
            reservation.date,
        )
        if same_day_reservations:
            raise ValueError("User may only create one reservation per day")

        vehicle = self.uow.vehicles.get(reservation.vehicle_id)
        if not vehicle:
            raise LookupError("Vehicle not found")

        if vehicle.user_id != reservation.user_id:
            raise ValueError("Vehicle does not belong to the authenticated user")

        if not vehicle.is_active:
            raise ValueError("Vehicle is not active")

        charger = self.uow.chargers.get(reservation.charger_id)
        if not charger:
            raise LookupError("Charger not found")

        if charger.status != "AVAILABLE":
            raise ValueError("Charger is not available")

        station = self.uow.stations.get(charger.station_id)
        if not station:
            raise LookupError("Station not found")
        if station.status != "AVAILABLE":
            raise ValueError("Station is not available")

        validate_vehicle_id(reservation, vehicle)
        validate_charger_id(reservation, charger)
        validate_compatibility(reservation, vehicle, charger)

        self.check_reservation_availability(reservation)

    def check_reservation_availability(self, reservation: ReservationEntity) -> None:
        charger_conflicts = self.uow.reservations.list_overlapping_by_charger(
            reservation.charger_id,
            reservation.date,
            reservation.start_time,
            reservation.end_time,
        )
        user_conflicts = self.uow.reservations.list_overlapping_by_user(
            reservation.user_id,
            reservation.date,
            reservation.start_time,
            reservation.end_time,
        )

        try:
            validate_reservation_conflicts(reservation, charger_conflicts)
            validate_user_reservation_conflicts(reservation, user_conflicts)
        except ValueError as exc:
            raise ReservationConflictError(
                "Selected time slot is already occupied."
            ) from exc

    def checkReservationAvailability(self, reservation: ReservationEntity) -> None:
        self.check_reservation_availability(reservation)

    def _delete_future_reservations(self, reservation: ReservationEntity) -> None:
        future_reservations = self.uow.reservations.list_by_user_after_date(
            reservation.user_id,
            reservation.date,
        )
        for future in future_reservations:
            self.uow.reservations.delete(future)

    def update_reservation_status(
        self,
        reservation_id: int,
        status: str,
        current_user_id: int,
        current_user_is_staff: bool = False,
    ) -> ReservationEntity:
        with self.uow:
            reservation = self.uow.reservations.get(reservation_id)
            if not reservation:
                raise LookupError("Reservation not found")
            if reservation.user_id != current_user_id and not current_user_is_staff:
                raise PermissionError("Not enough permissions")

            reservation.status = status.upper()
            validate_reservation_status(reservation)

            updated = self.uow.reservations.update(reservation)
            if reservation.status in {"EXPIRED", "CANCELLED"}:
                bad_count = self.uow.reservations.get_expired_or_cancelled_count_last_2_months(
                    reservation.user_id
                )
                if bad_count >= 2:
                    self._delete_future_reservations(reservation)
            return updated
