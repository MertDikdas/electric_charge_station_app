from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.vehicle import VehicleEntity


class VehicleService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_vehicle(self, vehicle: VehicleEntity) -> VehicleEntity:
        with self.uow:
            new_vehicle = self.uow.vehicles.add(vehicle)
            self.uow.commit()
            return new_vehicle

    def get_all_vehicles(self) -> List[VehicleEntity]:
        with self.uow:
            return self.uow.vehicles.list()

    def get_vehicle(self, vehicle_id: int) -> Optional[VehicleEntity]:
        with self.uow:
            return self.uow.vehicles.get(vehicle_id)
