from typing import List

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
            location=entity.location,
            status=entity.status.upper(),
        )

    def to_entity(self, model: StationModel) -> StationEntity:
        return StationEntity(
            id=model.id,
            address=model.address,
            company=model.company,
            location=model.location,
            status=model.status,
        )

    def list_by_status(self, status: str) -> List[StationEntity]:
        models = (
            self.session.query(StationModel)
            .filter(StationModel.status == status.upper())
            .all()
        )
        return [self.to_entity(model) for model in models]
