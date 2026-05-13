from app.core.uow import AbstractUnitOfWork
from app.domain.models.notification import NotificationEntity
from app.domain.models.charger import ChargerEntity
from app.domain.models.station import StationEntity
from app.domain.rules.station_rules import normalize_station_status, validate_station_status
from typing import Any, Dict, List, Optional
from datetime import datetime, timezone
from app.core.time_utils import now_in_turkey

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

    def get_stations_by_company_id(self, company_id: int) -> List[StationEntity]:
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            return self.uow.stations.list_by_company_id(company_id)

    def get_company_monthly_revenue(self, company_id: int, year: int, month: int) -> float:
        self._validate_year_month(year, month)
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            return self.uow.charging_sessions.get_monthly_revenue_by_company(
                company_id,
                year,
                month,
            )

    def get_station_monthly_revenue(self, station_id: int, year: int, month: int) -> float:
        self._validate_year_month(year, month)
        with self.uow:
            station = self.uow.stations.get(station_id)
            if not station:
                raise ValueError("Station not found")
            return self.uow.charging_sessions.get_monthly_revenue_by_station(
                station_id,
                year,
                month,
            )

    def get_company_station_usage_counts(self, company_id: int) -> list[dict[str, int | str]]:
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            return [
                {
                    "station_id": station_id,
                    "station_name": station_name,
                    "usage_count": usage_count,
                }
                for station_id, station_name, usage_count
                in self.uow.charging_sessions.get_usage_counts_by_company(company_id)
            ]

    def get_station(self, station_id: int) -> Optional[StationEntity]:
        with self.uow:
            return self.uow.stations.get(station_id)

    def _validate_year_month(self, year: int, month: int) -> None:
        if year < 2000:
            raise ValueError("Year is invalid")
        if month < 1 or month > 12:
            raise ValueError("Month must be between 1 and 12")

    def get_nearby_stations(self, latitude: float, longitude: float, km_radius: float) -> List[StationEntity]:
        with self.uow:
            return self.uow.stations.list_nearby(latitude, longitude)

    def get_nearby_stations_in_area(self, north_latitude: float, south_latitude: float, east_longitude: float, west_longitude: float) -> List[StationEntity]:
        with self.uow:
            return self.uow.stations.list_nearby_in_area(north_latitude, south_latitude, east_longitude, west_longitude)

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

            now = now_in_turkey()
            result = []

            for station in stations:
                compatible_chargers = []

                for charger in station.chargers:
                    if (
                        charger.connector_type == vehicle.connector_type
                        and charger.current_type == vehicle.current_type
                    ):
                        is_reserved_now = self.uow.reservations.exists_active_for_charger(
                            charger_id=charger.id,
                            now=now,
                        )

                        charger.is_reserved_now = is_reserved_now
                        compatible_chargers.append(charger)

                if not compatible_chargers:
                    continue

                station.chargers = compatible_chargers
                result.append(station)

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
            self.uow.stations.update(station)
            updated_station = self.uow.stations.update(station)
            self._create_station_unavailable_notifications(updated_station)
            self.uow.commit()
            return station

    def _create_station_unavailable_notifications(self, station: StationEntity) -> None:
        unavailable_statuses = {"CLOSED", "OUT_OF_SERVICE", "MAINTENANCE"}
        if station.status not in unavailable_statuses:
            return

        chargers = self.uow.chargers.list_by_station(station.id)
        charger_ids = [charger.id for charger in chargers if charger.id is not None]
        reservations = self.uow.reservations.list_active_for_chargers(
            charger_ids,
            now_in_turkey(),
        )

        title = "Reserved station unavailable"
        for reservation in reservations:
            message = (
                f"Your reserved station #{station.id} is temporarily unavailable. "
                f"Reservation #{reservation.id} may be affected."
            )
            if self.uow.notifications.exists_by_user_and_title_and_message(
                reservation.user_id,
                title,
                message,
            ):
                continue

            self.uow.notifications.add(
                NotificationEntity(
                    user_id=reservation.user_id,
                    title=title,
                    message=message,
                    notification_type="WARNING",
                )
            )

    def delete_station(self, station_id: int) -> None:
        with self.uow:
            station = self.uow.stations.get(station_id)
            if station:
                self.uow.stations.delete(station)
                self.uow.commit()
    
