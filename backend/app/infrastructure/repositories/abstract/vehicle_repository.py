from abc import abstractmethod
from typing import List

from app.domain.models.vehicle import VehicleEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractVehicleRepository(AbstractRepository[VehicleEntity]):
    @abstractmethod
    def list_by_user_id(self, user_id: int) -> List[VehicleEntity]:
        raise NotImplementedError

    @abstractmethod
    def update(self, vehicle: VehicleEntity) -> None:
        raise NotImplementedError
    
    @abstractmethod
    def get_by_id(self, vehicle_id: int) -> VehicleEntity | None:
        raise NotImplementedError