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

def normalize_vehicle_data(vehicle: VehicleEntity) -> None:
    vehicle.model = vehicle.model.strip()
    vehicle.plate = vehicle.plate.strip().upper()
    vehicle.connector_type = vehicle.connector_type.strip().upper()
    vehicle.current_type = vehicle.current_type.strip().upper()

def ensure_vehicle_plate_unique(vehicle: VehicleEntity, existing_vehicles: list[VehicleEntity]) -> None:
    for existing_vehicle in existing_vehicles:
        if existing_vehicle.plate == vehicle.plate and existing_vehicle.id != vehicle.id and existing_vehicle.is_active:
            raise ValueError("Vehicle plate must be unique")

def validate_battery_capacity(vehicle: VehicleEntity) -> None:
    if vehicle.battery_capacity <= 0:
        raise ValueError("Battery capacity must be greater than 0")

def validate_max_charging_power(vehicle: VehicleEntity) -> None:
    if vehicle.max_charging_power <= 0:
        raise ValueError("Max charging power must be greater than 0")

def validate_current_type(vehicle: VehicleEntity) -> None:
    if vehicle.current_type not in ALLOWED_CURRENT_TYPES:
        raise ValueError("Current type must be AC or DC")


def validate_connector_type(vehicle: VehicleEntity) -> None:
    if vehicle.connector_type not in ALLOWED_CONNECTOR_TYPES:
        raise ValueError("Connector type is not supported")


def validate_vehicle(vehicle: VehicleEntity) -> None:
    normalize_vehicle_data(vehicle)
    validate_battery_capacity(vehicle)
    validate_max_charging_power(vehicle)
    validate_current_type(vehicle)
    validate_connector_type(vehicle)
