from typing import List

from math import cos, radians
from app.utils.geo import calculate_distance
from app.domain.models.station import StationEntity
from app.infrastructure.database.tables import Station as StationModel
from app.infrastructure.repositories.abstract.station_repository import (
    AbstractStationRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyStationRepository(
    SqlAlchemyRepository[StationEntity, StationModel],
    AbstractStationRepository,
):
    model = StationModel

    def to_model(self, entity: StationEntity) -> StationModel:
        return StationModel(
            id=entity.id,
            address=entity.address,
            company=entity.company,
            latitude=entity.latitude,
            longitude=entity.longitude,
            status=entity.status.upper(),
        )

    def to_entity(self, model: StationModel) -> StationEntity:
        return StationEntity(
            id=model.id,
            address=model.address,
            company=model.company,
            latitude=model.latitude,
            longitude=model.longitude,
            status=model.status,
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
            model.address = station.address
            model.company = station.company
            model.latitude = station.latitude
            model.longitude = station.longitude
            model.status = station.status.upper()

    def list_nearby_in_area(self, north_latitude: float, south_latitude: float, east_longitude: float, west_longitude: float, radius: float) -> List[StationEntity]:
        models = (
            self.session.query(StationModel)
            .filter(StationModel.latitude >= south_latitude, StationModel.latitude <= north_latitude)
            .filter(StationModel.longitude >= west_longitude, StationModel.longitude <= east_longitude)
            .all()
        )
        return [self.to_entity(model) for model in models]