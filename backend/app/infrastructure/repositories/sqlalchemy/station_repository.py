from typing import List

from app.infrastructure.database.tables import Station
from app.infrastructure.repositories.abstract.station_repository import (
    AbstractStationRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyStationRepository(
    SqlAlchemyRepository[Station],
    AbstractStationRepository,
):
    model = Station

    def list_by_status(self, status: str) -> List[Station]:
        return self.session.query(Station).filter(Station.status == status).all()
