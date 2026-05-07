from app.core.uow import AbstractUnitOfWork
from app.domain.models.charger import ChargerEntity
from app.domain.models.station import StationEntity
from app.domain.rules.station_rules import normalize_station_status, validate_station_status
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

    def update_station_status(self, station_id: int, status: str) -> Optional[StationEntity]:
        with self.uow:
            normalized_status = normalize_station_status(status)
            validate_station_status(normalized_status)

            station = self.uow.stations.get(station_id)
            if not station:
                return None

            station.status = normalized_status
            updated_station = self.uow.stations.update(station)
            self.uow.commit()
            return updated_station

    def delete_station(self, station_id: int) -> None:
        with self.uow:
            station = self.uow.stations.get(station_id)
            if station:
                self.uow.stations.delete(station)
                self.uow.commit()
