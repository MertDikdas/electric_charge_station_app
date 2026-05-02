from app.domain.models import Vehicle, Charger

def are_compatible(vehicle: Vehicle, charger: Charger) -> bool:
    return (
        vehicle.connector_type == charger.connector_type and
        vehicle.current_type == charger.current_type
    )

def find_compatible_chargers(vehicle: Vehicle, chargers: list[Charger]) -> list[Charger]:
    return [charger for charger in chargers if are_compatible(vehicle, charger)]


