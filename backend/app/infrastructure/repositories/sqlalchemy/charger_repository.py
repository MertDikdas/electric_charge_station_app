from typing import List

from app.infrastructure.database.tables import Charger
from app.infrastructure.repositories.abstract.charger_repository import (
    AbstractChargerRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyChargerRepository(
    SqlAlchemyRepository[Charger],
    AbstractChargerRepository,
):
    model = Charger

    def list_by_station(self, station_id: int) -> List[Charger]:
        return self.session.query(Charger).filter(Charger.station_id == station_id).all()

    def list_by_status(self, status: str) -> List[Charger]:
        return self.session.query(Charger).filter(Charger.status == status).all()
