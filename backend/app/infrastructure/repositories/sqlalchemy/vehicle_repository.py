from typing import List

from app.infrastructure.database.tables import Vehicle
from app.infrastructure.repositories.abstract.vehicle_repository import (
    AbstractVehicleRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyVehicleRepository(
    SqlAlchemyRepository[Vehicle],
    AbstractVehicleRepository,
):
    model = Vehicle

    def list_by_user(self, user_id: int) -> List[Vehicle]:
        return self.session.query(Vehicle).filter(Vehicle.user_id == user_id).all()
