from typing import Optional

from app.domain.models.charging_session import ChargingSessionEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractChargingSessionRepository(AbstractRepository[ChargingSessionEntity]):
    def get_by_reservation_id(self, reservation_id: int) -> Optional[ChargingSessionEntity]:
        return self.get(reservation_id)

    def list_by_user_id(self, user_id: int) -> list[ChargingSessionEntity]:
        raise NotImplementedError