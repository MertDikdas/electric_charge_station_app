from abc import abstractmethod
from typing import List

from app.domain.models.station import StationEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractStationRepository(AbstractRepository[StationEntity]):
    @abstractmethod
    def list_by_status(self, status: str) -> List[StationEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_nearby(self, latitude: float, longitude: float) -> List[StationEntity]:
        raise NotImplementedError

    @abstractmethod
    def update(self, station: StationEntity) -> None:
        raise NotImplementedError

    @abstractmethod
    def list_nearby_in_area(self, north_latitude: float, south_latitude: float, east_longitude: float, west_longitude: float, radius: float) -> List[StationEntity]:
        raise NotImplementedError