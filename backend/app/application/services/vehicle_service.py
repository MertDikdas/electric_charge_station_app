from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.vehicle import VehicleCreate, Vehicle


class VehicleService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_vehicle(self, vehicle_in: VehicleCreate) -> Vehicle:
        with self.uow:
            new_vehicle = Vehicle(**vehicle_in.model_dump(), id=0)
            self.uow.vehicles.add(new_vehicle)
            self.uow.commit()
            return new_vehicle

    def get_all_vehicles(self) -> List[Vehicle]:
        with self.uow:
            return self.uow.vehicles.list()

    def get_vehicle(self, vehicle_id: int) -> Optional[Vehicle]:
        with self.uow:
            return self.uow.vehicles.get(vehicle_id)
