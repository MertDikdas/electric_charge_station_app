from typing import List

from app.domain.models.charger import ChargerEntity
from app.infrastructure.database.tables import Charger as ChargerModel
from app.infrastructure.repositories.abstract.charger_repository import (
    AbstractChargerRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyChargerRepository(
    SqlAlchemyRepository[ChargerEntity, ChargerModel],
    AbstractChargerRepository,
):
    model = ChargerModel

    def to_model(self, entity: ChargerEntity) -> ChargerModel:
        return ChargerModel(
            id=entity.id,
            station_id=entity.station_id,
            connector_type=entity.connector_type,
            current_type=entity.current_type,
            max_power=entity.max_power,
            price_per_kwh=entity.price_per_kwh,
            status=entity.status.upper(),
        )

    def to_entity(self, model: ChargerModel) -> ChargerEntity:
        return ChargerEntity(
            id=model.id,
            station_id=model.station_id,
            connector_type=model.connector_type,
            current_type=model.current_type,
            max_power=model.max_power,
            price_per_kwh=model.price_per_kwh,
            status=model.status,
        )

    def list_by_station(self, station_id: int) -> List[ChargerEntity]:
        models = (
            self.session.query(ChargerModel)
            .filter(ChargerModel.station_id == station_id)
            .all()
        )
        return [self.to_entity(model) for model in models]

    def list_by_status(self, status: str) -> List[ChargerEntity]:
        models = (
            self.session.query(ChargerModel)
            .filter(ChargerModel.status == status.upper())
            .all()
        )
        return [self.to_entity(model) for model in models]
