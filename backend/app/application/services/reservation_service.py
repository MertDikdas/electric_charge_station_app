from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.reservation import ReservationEntity
from app.domain.rules.reservation_rules import (
    ensure_reservation_not_in_past,
    ensure_reservation_not_too_far_in_future,
    validate_reservation,
    validate_reservation_conflicts,
    validate_reservation_duration,
    validate_reservation_time,
    add_minutes_to_time,
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

    def _validate_reservation_request(self, reservation: ReservationEntity) -> None:
        if not validate_reservation_time(reservation):
            raise ValueError("Reservation end_time must be after start_time")

        if reservation.status not in self.allowed_statuses:
            raise ValueError("Reservation status must be PENDING or CONFIRMED")

        if not ensure_reservation_not_in_past(reservation):
            raise ValueError("Reservation cannot be in the past")

        if not ensure_reservation_not_too_far_in_future(reservation):
            raise ValueError("Reservation cannot be more than 30 days in the future")

        if not validate_reservation_duration(reservation):
            raise ValueError("Reservation duration cannot exceed 2 hours")

        user = self.uow.users.get(reservation.user_id)
        if not user:
            raise LookupError("User not found")

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

        if not validate_reservation(reservation, vehicle, charger):
            raise ValueError("Vehicle is not compatible with charger")

        charger_conflicts = self.uow.reservations.list_overlapping_by_charger(
            reservation.charger_id,
            reservation.date,
            add_minutes_to_time(reservation.start_time, BUFFER_MINUTES),
            reservation.end_time,
        )
        if not validate_reservation_conflicts(reservation, charger_conflicts, BUFFER_MINUTES):
            raise ValueError("Charger already has a reservation in this time range")

        user_conflicts = self.uow.reservations.list_overlapping_by_user(
            reservation.user_id,
            reservation.date,
            reservation.start_time,
            reservation.end_time,
        )
        if user_conflicts:
            raise ValueError("User already has a reservation in this time range")
