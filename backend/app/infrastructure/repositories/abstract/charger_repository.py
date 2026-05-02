from abc import abstractmethod
from typing import List

from app.infrastructure.database.tables import Charger
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractChargerRepository(AbstractRepository[Charger]):
    @abstractmethod
    def list_by_station(self, station_id: int) -> List[Charger]:
        raise NotImplementedError

    @abstractmethod
    def list_by_status(self, status: str) -> List[Charger]:
        raise NotImplementedError
