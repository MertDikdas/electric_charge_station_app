from app.models.station import StationCreate, Station
from app.core.uow import AbstractUnitOfWork
from typing import List, Optional

class StationService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_station(self, station_in: StationCreate) -> Station:
        with self.uow:
            new_station = Station(**station_in.model_dump(), id=0)
            self.uow.stations.add(new_station)
            self.uow.commit()
            return new_station

    def get_all_stations(self) -> List[Station]:
        with self.uow:
            return self.uow.stations.list()

    def get_station(self, station_id: int) -> Optional[Station]:
        with self.uow:
            return self.uow.stations.get(station_id)
