from app.core.uow import AbstractUnitOfWork
from app.domain.models.station import StationEntity
from typing import List, Optional

class StationService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_station(self, station: StationEntity) -> StationEntity:
        with self.uow:
            new_station = self.uow.stations.add(station)
            self.uow.commit()
            return new_station

    def get_all_stations(self) -> List[StationEntity]:
        with self.uow:
            return self.uow.stations.list()

    def get_station(self, station_id: int) -> Optional[StationEntity]:
        with self.uow:
            return self.uow.stations.get(station_id)
