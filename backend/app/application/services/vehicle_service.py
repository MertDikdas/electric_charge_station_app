from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.charger import ChargerEntity
from app.domain.models.vehicle import VehicleEntity
from app.domain.rules.compatibility_rules import find_compatible_chargers
from app.domain.rules.vehicle_rules import validate_vehicle


class VehicleService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_vehicle(self, vehicle: VehicleEntity, current_user_id: int) -> VehicleEntity:
        with self.uow:
            user = self.uow.users.get(current_user_id)
            if not user:
                raise LookupError("User not found")

            vehicle.user_id = current_user_id
            validate_vehicle(vehicle)
            new_vehicle = self.uow.vehicles.add(vehicle)
            self.uow.commit()
            return new_vehicle

    def get_all_vehicles(self) -> List[VehicleEntity]:
        with self.uow:
            return self.uow.vehicles.list()

    def get_vehicle(self, vehicle_id: int) -> Optional[VehicleEntity]:
        with self.uow:
            return self.uow.vehicles.get(vehicle_id)

    def get_compatible_chargers(self, vehicle_id: int) -> Optional[List[ChargerEntity]]:
        with self.uow:
            vehicle = self.uow.vehicles.get(vehicle_id)
            if not vehicle:
                return None
            chargers = self.uow.chargers.list()
            return find_compatible_chargers(vehicle, chargers)

    def delete_vehicle(self, vehicle_id: int) -> bool:
        with self.uow:
            vehicle = self.uow.vehicles.get(vehicle_id)
            if not vehicle:
                return False
            self.uow.vehicles.delete(vehicle)
            self.uow.commit()
            return True

    def update_vehicle(self, vehicle: VehicleEntity) -> VehicleEntity:
        with self.uow:
            validate_vehicle(vehicle)
            self.uow.vehicles.update(vehicle)
            self.uow.commit()
            return vehicle
