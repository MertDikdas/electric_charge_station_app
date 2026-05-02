from abc import abstractmethod
from typing import List

from app.infrastructure.database.tables import Vehicle
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractVehicleRepository(AbstractRepository[Vehicle]):
    @abstractmethod
    def list_by_user(self, user_id: int) -> List[Vehicle]:
        raise NotImplementedError
