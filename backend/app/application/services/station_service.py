from app.core.uow import AbstractUnitOfWork
from app.domain.models.charger import ChargerEntity
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

    def get_nearby_stations(self, location: str) -> List[StationEntity]:
        with self.uow:
            return self.uow.stations.list_nearby(location)

    def get_station_chargers(self, station_id: int) -> List[ChargerEntity]:
        with self.uow:
            return self.uow.chargers.list_by_station(station_id)

    def update_station(self, station: StationEntity) -> StationEntity:
        with self.uow:
            self.uow.stations.update(station)
            self.uow.commit()
            return station

    def delete_station(self, station_id: int) -> None:
        with self.uow:
            station = self.uow.stations.get(station_id)
            if station:
                self.uow.stations.delete(station)
                self.uow.commit()
