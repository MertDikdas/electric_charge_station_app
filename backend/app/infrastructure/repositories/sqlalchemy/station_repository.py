from typing import List

from math import cos, radians
from app.domain.models.station import StationEntity
from app.infrastructure.database.tables import Station as StationModel
from app.infrastructure.repositories.abstract.station_repository import (
    AbstractStationRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository
from app.domain.models.charger import ChargerEntity
from sqlalchemy.orm import joinedload


class SqlAlchemyStationRepository(
    SqlAlchemyRepository[StationEntity, StationModel],
    AbstractStationRepository,
):
    model = StationModel

    def to_model(self, entity: StationEntity) -> StationModel:
        return StationModel(
            id=entity.id,
            name=entity.name,
            address=entity.address,
            company_id=entity.company_id,
            latitude=entity.latitude,
            longitude=entity.longitude,
            status=entity.status.upper(),

        )

    def to_entity(self, model: StationModel) -> StationEntity:
        return StationEntity(
            id=model.id,
            name=model.name,
            address=model.address,
            company_id=model.company_id,
            latitude=model.latitude,
            longitude=model.longitude,
            status=model.status,
            chargers=[
                ChargerEntity(
                    id=charger.id,
                    station_id=charger.station_id,
                    connector_type=charger.connector_type,
                    current_type=charger.current_type,
                    max_power=charger.max_power,
                    price_per_kwh=charger.price_per_kwh,
                    status=charger.status,
                )
                for charger in model.chargers
            ],

        )

    def list_by_status(self, status: str) -> List[StationEntity]:
        models = (
            self.session.query(StationModel)
            .filter(StationModel.status == status.upper())
            .all()
        )
        return [self.to_entity(model) for model in models]

    def list_nearby(self, latitude: float, longitude: float, km_radius: float) -> List[StationEntity]:
        lat_delta = km_radius / 111.0

        lon_delta = km_radius / (111.0 * cos(radians(latitude)))

        models = (
            self.session.query(StationModel)
            .filter(StationModel.latitude >= latitude - lat_delta)
            .filter(StationModel.latitude <= latitude + lat_delta)
            .filter(StationModel.longitude >= longitude - lon_delta)
            .filter(StationModel.longitude <= longitude + lon_delta)
            .all()
        )

        return [self.to_entity(model) for model in models]

    def update(self, station: StationEntity) -> None:
        model = self.session.get(StationModel, station.id)
        if model:
            model.name = station.name
            model.address = station.address
            model.company_id = station.company_id
            model.latitude = station.latitude
            model.longitude = station.longitude
            model.status = station.status.upper()

    def list_nearby_in_area(self, north_latitude: float, south_latitude: float, east_longitude: float, west_longitude: float) -> List[StationEntity]:
        models = (
            self.session.query(StationModel)
            .options(joinedload(StationModel.chargers))
            .filter(StationModel.latitude >= south_latitude, StationModel.latitude <= north_latitude)
            .filter(StationModel.longitude >= west_longitude, StationModel.longitude <= east_longitude)
            .all()
        )
        return [self.to_entity(model) for model in models]
