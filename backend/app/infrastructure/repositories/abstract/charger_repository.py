from abc import abstractmethod
from typing import List

from app.domain.models.charger import ChargerEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractChargerRepository(AbstractRepository[ChargerEntity]):
    @abstractmethod
    def list_by_station(self, station_id: int) -> List[ChargerEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_status(self, status: str) -> List[ChargerEntity]:
        raise NotImplementedError
