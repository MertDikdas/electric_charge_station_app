from app.domain.models import Vehicle, Charger, Reservation
from app.domain.rules.compatibility_rules import are_compatible
from datetime import datetime, timedelta, timezone, time

def to_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

def add_minutes_to_time(t, minutes: int):
    return (datetime.combine(datetime.today(), t) + timedelta(minutes=minutes)).time()

def calculate_end_time(start_time: time, duration_minutes: int) -> time:
    return add_minutes_to_time(start_time, duration_minutes)

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
    if reservation.end_time is None:
        raise ValueError("Reservation end_time is required")
    if reservation.start_time >= reservation.end_time:
        raise ValueError("Reservation start_time must be before end_time")

def validate_reservation_conflicts(reservation: Reservation, existing_reservations: list[Reservation]) -> None:
    """Checks whether the reservation conflicts with existing reservations for the same charger."""
    for existing in existing_reservations:
        if existing.charger_id == reservation.charger_id:
            if (reservation.start_time < existing.end_time and reservation.end_time > existing.start_time):
                raise ValueError("Reservation conflicts with an existing reservation for the same charger")

def validate_reservation_duration(
    reservation: Reservation,
    min_minutes: int = 15,
    max_minutes: int = 120,
) -> None:
    """Checks whether the reservation duration is within the allowed range."""
    if reservation.end_time is None:
        raise ValueError("Reservation end_time is required")
    start_at = datetime.combine(reservation.date, reservation.start_time)
    end_at = datetime.combine(reservation.date, reservation.end_time)
    duration = end_at - start_at
    if duration < timedelta(minutes=min_minutes):
        raise ValueError("Reservation duration must be at least 15 minutes")
    if duration > timedelta(minutes=max_minutes):
        raise ValueError("Reservation duration cannot exceed 2 hours")
    if duration.total_seconds() % (15 * 60) != 0:
        raise ValueError("Reservation duration must align to 15-minute slots")

def validate_reservation_slot_interval(reservation: Reservation, interval_minutes: int = 15) -> None:
    """Checks whether the reservation range aligns to the slot interval."""
    if reservation.start_time.minute % interval_minutes != 0 or reservation.start_time.second != 0:
        raise ValueError("Reservation start_time must align to 15-minute slots")
    if reservation.end_time is None:
        raise ValueError("Reservation end_time is required")
    if reservation.end_time.minute % interval_minutes != 0 or reservation.end_time.second != 0:
        raise ValueError("Reservation end_time must align to 15-minute slots")

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
        raise ValueError("Reservation is too far in the future")

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
