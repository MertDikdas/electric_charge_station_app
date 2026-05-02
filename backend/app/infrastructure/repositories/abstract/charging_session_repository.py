from typing import Optional

from app.infrastructure.database.tables import ChargingSession
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractChargingSessionRepository(AbstractRepository[ChargingSession]):
    def get_by_reservation_id(self, reservation_id: int) -> Optional[ChargingSession]:
        return self.get(reservation_id)
