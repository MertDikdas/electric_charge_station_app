from app.domain.models import Vehicle, Charger
from app.domain.rules.compatibility_rules import are_compatible

def is_charger_available(charger: Charger) -> bool:
    """Checks whether the charger is available for reservation."""
    return charger.status == "AVAILABLE"


def can_start_charging_session(charger: Charger, vehicle: Vehicle) -> bool:
    """Checks whether a charging session can be started with the given charger and vehicle."""
    return is_charger_available(charger) and are_compatible(vehicle, charger)