from abc import abstractmethod
from typing import List

from app.infrastructure.database.tables import Station
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractStationRepository(AbstractRepository[Station]):
    @abstractmethod
    def list_by_status(self, status: str) -> List[Station]:
        raise NotImplementedError
