from typing import List, Optional
from datetime import date

from app.core.uow import AbstractUnitOfWork
from app.domain.models.reservation import ReservationEntity
from app.domain.rules.reservation_rules import (
    ensure_reservation_not_in_past,
    ensure_reservation_not_too_far_in_future,
    validate_reservation_conflicts,
    validate_reservation_duration,
    validate_reservation_time,
    add_minutes_to_time,
    validate_reservation_status,
    validate_charger_id,
    validate_vehicle_id,
    validate_compatibility,
    validate_user_reservation_conflicts,
)

BUFFER_MINUTES = 10

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
            self._validate_reservation_request(reservation)

            new_reservation = self.uow.reservations.add(reservation)
            self.uow.commit()
            return new_reservation

    def get_all_reservations(self) -> List[ReservationEntity]:
        with self.uow:
            return self.uow.reservations.list()

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
        validate_reservation_status(reservation)

        ensure_reservation_not_in_past(reservation)
        ensure_reservation_not_too_far_in_future(reservation)
        validate_reservation_duration(reservation)
        
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

        validate_vehicle_id(reservation, vehicle)
        validate_charger_id(reservation, charger)
        validate_compatibility(reservation, vehicle, charger)

        charger_conflicts = self.uow.reservations.list_overlapping_by_charger(
            reservation.charger_id,
            reservation.date,
            add_minutes_to_time(reservation.start_time, BUFFER_MINUTES),
            reservation.end_time,
        )
        validate_reservation_conflicts(reservation, charger_conflicts, BUFFER_MINUTES)

        user_conflicts = self.uow.reservations.list_overlapping_by_user(
            reservation.user_id,
            reservation.date,
            reservation.start_time,
            reservation.end_time,
        )
        validate_user_reservation_conflicts(reservation, user_conflicts)