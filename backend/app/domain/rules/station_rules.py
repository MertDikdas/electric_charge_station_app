from app.domain.models.station import StationEntity


def normalize_station_status(status: str) -> str:
    return status.strip().upper()

def validate_station_company(company: str) -> None:
    if not company:
        raise ValueError("Station company cannot be empty")
    if len(company) > 100:
        raise ValueError("Station company cannot exceed 100 characters")
    if len(company) < 2:
        raise ValueError("Station company must be at least 2 characters long")

def validate_station_address(address: str) -> None:
    if not address:
        raise ValueError("Station address cannot be empty")
    if len(address) > 300:
        raise ValueError("Station address cannot exceed 300 characters")
    if len(address) < 2:
        raise ValueError("Station address must be at least 2 characters long")

def validate_station_location(location: str) -> None:
    if not location:
        raise ValueError("Station location cannot be empty")
    if len(location) > 200:
        raise ValueError("Station location cannot exceed 200 characters")
    if len(location) < 2:
        raise ValueError("Station location must be at least 2 characters long")


def validate_station_status(status: str) -> None:
    valid_statuses = {'AVAILABLE', 'OCCUPIED', 'OUT_OF_SERVICE', 'MAINTENANCE', 'CLOSED'}
    if status not in valid_statuses:
        raise ValueError(f"Station status must be one of {valid_statuses}")


def validate_station_entity(station: StationEntity) -> None:
    station.status = normalize_station_status(station.status)
    validate_station_company(station.company)
    validate_station_location(station.location)
    validate_station_status(station.status)
    validate_station_address(station.address)