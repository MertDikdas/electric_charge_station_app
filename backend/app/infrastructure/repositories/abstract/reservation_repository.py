from abc import abstractmethod
from datetime import date
from typing import List

from app.domain.models.reservation import ReservationEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractReservationRepository(AbstractRepository[ReservationEntity]):
    @abstractmethod
    def list_by_user(self, user_id: int) -> List[ReservationEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_charger_and_date(
        self,
        charger_id: int,
        reservation_date: date,
    ) -> List[ReservationEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_user_id(self, user_id: int) -> List[ReservationEntity]:
        raise NotImplementedError