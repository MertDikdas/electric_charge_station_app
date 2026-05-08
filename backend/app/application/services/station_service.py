from app.core.uow import AbstractUnitOfWork
from app.domain.models.charger import ChargerEntity
from app.domain.models.station import StationEntity
from app.domain.rules.station_rules import normalize_station_status, validate_station_status
from typing import Any, Dict, List, Optional

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

    def get_nearby_stations(self, latitude: float, longitude: float, km_radius: float) -> List[StationEntity]:
        with self.uow:
            return self.uow.stations.list_nearby(latitude, longitude)

    def get_nearby_stations_in_area(self, north_latitude: float, south_latitude: float, east_longitude: float, west_longitude: float, radius: float) -> List[StationEntity]:
        with self.uow:
            return self.uow.stations.list_nearby_in_area(north_latitude, south_latitude, east_longitude, west_longitude, radius)

    def get_station_chargers(self, station_id: int) -> List[ChargerEntity]:
        with self.uow:
            return self.uow.chargers.list_by_station(station_id)

    def get_nearby_compatible_stations(self, north_latitude: float, south_latitude: float, east_longitude: float, west_longitude: float, vehicle_id: int, current_user_id: int) -> List[Dict[str, Any]]:
        with self.uow:
            vehicle = self.uow.vehicles.get_by_id(vehicle_id)

            if vehicle is None:
                raise ValueError("Vehicle not found")

            if vehicle.user_id != current_user_id:
                raise PermissionError("You can only search with your own vehicle")

            stations = self.uow.stations.list_nearby_in_area(
                north_latitude=north_latitude,
                south_latitude=south_latitude,
                east_longitude=east_longitude,
                west_longitude=west_longitude,
            )

            result = []

            for station in stations:
                compatible_chargers = [
                    charger
                    for charger in station.chargers
                    if charger.connector_type == vehicle.connector_type
                    and charger.current_type == vehicle.current_type
                ]

                if not compatible_chargers:
                    continue

                compatible_available_count = sum(
                    1
                    for charger in compatible_chargers
                    if charger.status == "AVAILABLE"
                )

                result.append({
                    "id": station.id,
                    "company_id": station.company_id,
                    "address": station.address,
                    "latitude": station.latitude,
                    "longitude": station.longitude,
                    "availability": self._calculate_station_availability(
                        compatible_chargers
                    ),
                    "compatible_available_charger_count": compatible_available_count,
                    "compatible_total_charger_count": len(compatible_chargers),
                    "connector_type": vehicle.connector_type,
                    "current_type": vehicle.current_type,
                })

            return result
        
    def _calculate_station_availability(self, compatible_chargers) -> str:
        print(compatible_chargers)
        if not compatible_chargers:
            return "UNAVAILABLE"
        
        if any(charger.status == "AVAILABLE" for charger in compatible_chargers):
            return "AVAILABLE"

        if any(charger.status == "OCCUPIED" for charger in compatible_chargers):
            return "FULL"

        return "OUT_OF_SERVICE"
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
    
