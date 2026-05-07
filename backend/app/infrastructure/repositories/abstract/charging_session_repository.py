from abc import abstractmethod
from datetime import datetime
from typing import Optional

from app.domain.models.charging_session import (
    ChargingSessionEntity,
    ExpiredChargingSessionForAutoFinish,
)
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractChargingSessionRepository(AbstractRepository[ChargingSessionEntity]):
    def get_by_reservation_id(self, reservation_id: int) -> Optional[ChargingSessionEntity]:
        return self.get(reservation_id)

    @abstractmethod
    def list_by_user_id(self, user_id: int) -> list[ChargingSessionEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_charger_id(self, charger_id: int) -> list[ChargingSessionEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_active_by_user_id(self, user_id: int) -> list[ChargingSessionEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_active_by_charger_id(self, charger_id: int) -> list[ChargingSessionEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_expired_for_auto_finish(
        self,
        current_datetime: datetime,
    ) -> list[ExpiredChargingSessionForAutoFinish]:
        raise NotImplementedError
