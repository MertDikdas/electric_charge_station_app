from app.domain.models import Vehicle, Charger, Reservation
from app.domain.rules.compatibility_rules import are_compatible
from datetime import datetime, timedelta, timezone

def to_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def get_start_datetime(reservation) -> datetime:
    return to_utc(datetime.combine(reservation.date, reservation.start_time))


def get_end_datetime(reservation) -> datetime:
    return to_utc(datetime.combine(reservation.date, reservation.end_time))

def validate_reservation(reservation: Reservation, vehicle: Vehicle, charger: Charger) -> bool:
    """Checks whether the reservation belongs to the given vehicle and charger."""
    if reservation.vehicle_id != vehicle.id:
        return False
    if reservation.charger_id != charger.id:
        return False
    if not are_compatible(vehicle, charger):
        return False
    return True

def validate_reservation_time(reservation: Reservation) -> bool:
    """Checks whether the reservation has a valid time range."""
    if reservation.start_time >= reservation.end_time:
        return False
    return True

def validate_reservation_conflicts(reservation: Reservation, existing_reservations: list[Reservation]) -> bool:
    """Checks whether the reservation conflicts with existing reservations for the same charger."""
    for existing in existing_reservations:
        if existing.charger_id == reservation.charger_id:
            if (reservation.start_time < existing.end_time and reservation.end_time > existing.start_time):
                return False
    return True

def validate_reservation_duration(reservation: Reservation, max_duration_hours: int = 2) -> bool:
    """Checks whether the reservation duration does not exceed the maximum allowed duration."""
    start_at = datetime.combine(reservation.date, reservation.start_time)
    end_at = datetime.combine(reservation.date, reservation.end_time)
    duration = end_at - start_at
    if duration > timedelta(hours=max_duration_hours):
        return False
    return True

def ensure_reservation_not_in_past(reservation: Reservation) -> bool:
    """Checks whether the reservation is not in the past."""
    start_at = get_start_datetime(reservation)
    return start_at >= datetime.now(timezone.utc)

def ensure_reservation_not_too_far_in_future(reservation: Reservation, max_future_days: int = 30) -> bool:
    """Checks whether the reservation is not too far in the future."""
    start_at = get_start_datetime(reservation)
    max_allowed_time = datetime.now(timezone.utc) + timedelta(days=max_future_days)
    return start_at <= max_allowed_time
