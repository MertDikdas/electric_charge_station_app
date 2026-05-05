from app.domain.models import Vehicle, Charger, Reservation
from app.domain.rules.compatibility_rules import are_compatible
from datetime import datetime, timedelta, timezone

def to_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

def add_minutes_to_time(t, minutes: int):
    return (datetime.combine(datetime.today(), t) + timedelta(minutes=minutes)).time()

def get_start_datetime(reservation) -> datetime:
    return to_utc(datetime.combine(reservation.date, reservation.start_time))


def get_end_datetime(reservation) -> datetime:
    return to_utc(datetime.combine(reservation.date, reservation.end_time))

def validate_vehicle_id(reservation: Reservation, vehicle: Vehicle) -> None:
    """Checks whether the reservation's vehicle_id matches the given vehicle."""
    if reservation.vehicle_id != vehicle.id:
        raise ValueError("Reservation vehicle_id does not match the given vehicle")

def validate_charger_id(reservation: Reservation, charger: Charger) -> None:
    """Checks whether the reservation's charger_id matches the given charger."""
    if reservation.charger_id != charger.id:
        raise ValueError("Reservation charger_id does not match the given charger")

def validate_compatibility(reservation: Reservation, vehicle: Vehicle, charger: Charger) -> None:
    """Checks whether the reservation's vehicle and charger are compatible."""
    if not are_compatible(vehicle, charger):
        raise ValueError("Reservation vehicle and charger are not compatible")

def validate_reservation_time(reservation: Reservation) -> None:
    """Checks whether the reservation has a valid time range."""
    if reservation.start_time >= reservation.end_time:
        raise ValueError("Reservation start_time must be before end_time")

def validate_reservation_conflicts(reservation: Reservation, existing_reservations: list[Reservation], buffer_minutes: int = 10) -> None:
    """Checks whether the reservation conflicts with existing reservations for the same charger."""
    for existing in existing_reservations:
        existing_end_with_buffer = add_minutes_to_time(existing.end_time, buffer_minutes)
        if existing.charger_id == reservation.charger_id:
            if (reservation.start_time < existing_end_with_buffer and reservation.end_time > existing.start_time):
                raise ValueError("Reservation conflicts with an existing reservation for the same charger")

def validate_reservation_duration(reservation: Reservation, max_duration_hours: int = 2) -> None:
    """Checks whether the reservation duration does not exceed the maximum allowed duration."""
    start_at = datetime.combine(reservation.date, reservation.start_time)
    end_at = datetime.combine(reservation.date, reservation.end_time)
    duration = end_at - start_at
    if duration > timedelta(hours=max_duration_hours):
        raise ValueError("Reservation duration exceeds the maximum allowed duration")

def ensure_reservation_not_in_past(reservation: Reservation) -> None:
    """Checks whether the reservation is not in the past."""
    start_at = get_start_datetime(reservation)
    if start_at < datetime.now(timezone.utc):
        raise ValueError("Reservation is in the past")

def ensure_reservation_not_too_far_in_future(reservation: Reservation, max_future_days: int = 30) -> None:
    """Checks whether the reservation is not too far in the future."""
    start_at = get_start_datetime(reservation)
    max_allowed_time = datetime.now(timezone.utc) + timedelta(days=max_future_days)
    if start_at > max_allowed_time:
        ValueError("Reservation is too far in the future")

def validate_reservation_status(reservation: Reservation) -> None:
    """Checks whether the reservation status is valid."""
    valid_statuses = {'PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED','EXPIRED', 'NO_SHOW'}
    if reservation.status not in valid_statuses:
        raise ValueError(f"Reservation status must be one of {valid_statuses}")

def validate_user_reservation_conflicts(reservation: Reservation, existing_reservations: list[Reservation]) -> None:
    """Checks whether the reservation conflicts with existing reservations for the same user."""
    for existing in existing_reservations:
        if existing.user_id == reservation.user_id:
            if (reservation.start_time < existing.end_time and reservation.end_time > existing.start_time):
                raise ValueError("User already has a reservation in this time range")