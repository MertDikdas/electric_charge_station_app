from app.domain.models.vehicle import VehicleEntity


ALLOWED_CURRENT_TYPES = {"AC", "DC"}
ALLOWED_CONNECTOR_TYPES = {
    "TYPE_1",
    "TYPE_2",
    "CCS1",
    "CCS2",
    "CHADEMO",
    "NACS",
    "GB_T_AC",
    "GB_T_DC",
    "TESLA_ROADSTER",
    "TESLA_TYPE_2",
}


def validate_vehicle(vehicle: VehicleEntity) -> None:
    if vehicle.battery_capacity <= 0:
        raise ValueError("Battery capacity must be greater than 0")

    if vehicle.max_charging_power <= 0:
        raise ValueError("Max charging power must be greater than 0")

    vehicle.current_type = vehicle.current_type.upper()
    if vehicle.current_type not in ALLOWED_CURRENT_TYPES:
        raise ValueError("Current type must be AC or DC")

    vehicle.connector_type = vehicle.connector_type.upper()
    if vehicle.connector_type not in ALLOWED_CONNECTOR_TYPES:
        raise ValueError("Connector type is not supported")
