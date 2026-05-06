from datetime import datetime

from app.domain.models import Charger, Vehicle, ChargingSession, Reservation


def validate_can_start_charging_session(
    charger: Charger,
    vehicle: Vehicle,
    active_reservations: Reservation | None,
    active_charging_sessions: list[ChargingSession],
) -> None:
    """Validates whether a charging session can be started with the given charger and vehicle."""
    if not charger.is_available():
        raise ValueError("Charger is not available")
    if not charger.is_compatible_with(vehicle):
        raise ValueError("Vehicle is not compatible with the charger")

    if active_reservations:
        reservation_start = datetime.combine(
            active_reservations.date,
            active_reservations.start_time,
        )
        reservation_end = datetime.combine(
            active_reservations.date,
            active_reservations.end_time,
        )
        current_datetime = datetime.now()

        if not (reservation_start <= current_datetime <= reservation_end):
            raise ValueError("Reservation time has not arrived or has already passed")

    if active_charging_sessions:
        raise ValueError("There are active charging sessions for this charger")
    