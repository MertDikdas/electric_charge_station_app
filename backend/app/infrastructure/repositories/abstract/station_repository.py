from abc import abstractmethod
from typing import List

from app.domain.models.station import StationEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractStationRepository(AbstractRepository[StationEntity]):
    @abstractmethod
    def list_by_status(self, status: str) -> List[StationEntity]:
        raise NotImplementedError
