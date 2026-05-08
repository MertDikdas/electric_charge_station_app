from app.domain.models.station import StationEntity


def normalize_station_status(status: str) -> str:
    return status.strip().upper()

def validate_station_address(address: str) -> None:
    if not address:
        raise ValueError("Station address cannot be empty")
    if len(address) > 300:
        raise ValueError("Station address cannot exceed 300 characters")
    if len(address) < 2:
        raise ValueError("Station address must be at least 2 characters long")


def validate_station_status(status: str) -> None:
    valid_statuses = {'AVAILABLE', 'OCCUPIED', 'OUT_OF_SERVICE', 'MAINTENANCE', 'CLOSED'}
    if status not in valid_statuses:
        raise ValueError(f"Station status must be one of {valid_statuses}")

def validate_station_location(latitude: float, longitude: float) -> None:
    if not isinstance(latitude, (int, float)):
        raise ValueError("Station latitude must be a number")
    if not isinstance(longitude, (int, float)):
        raise ValueError("Station longitude must be a number")
    if latitude < -90 or latitude > 90:
        raise ValueError("Station latitude must be between -90 and 90")
    if longitude < -180 or longitude > 180:
        raise ValueError("Station longitude must be between -180 and 180")

def validate_station_entity(station: StationEntity) -> None:
    station.status = normalize_station_status(station.status)
    validate_station_status(station.status)
    validate_station_address(station.address)
    validate_station_location(station.latitude, station.longitude)

def calculate_station_availability_by_compatible_chargers(compatible_chargers) -> str:
    if not compatible_chargers:
        return "UNAVAILABLE"

    available_count = sum(
        1 for charger in compatible_chargers
        if charger.status == "AVAILABLE"
    )

    if available_count > 0:
        return "AVAILABLE"

    active_count = sum(
        1 for charger in compatible_chargers
        if charger.status in {"AVAILABLE", "OCCUPIED"}
    )

    if active_count > 0:
        return "FULL"

    return "OUT_OF_SERVICE"
