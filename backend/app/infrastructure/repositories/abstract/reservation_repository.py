from abc import abstractmethod
from datetime import date
from typing import List

from app.infrastructure.database.tables import Reservation
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractReservationRepository(AbstractRepository[Reservation]):
    @abstractmethod
    def list_by_user(self, user_id: int) -> List[Reservation]:
        raise NotImplementedError

    @abstractmethod
    def list_by_charger_and_date(
        self,
        charger_id: int,
        reservation_date: date,
    ) -> List[Reservation]:
        raise NotImplementedError
