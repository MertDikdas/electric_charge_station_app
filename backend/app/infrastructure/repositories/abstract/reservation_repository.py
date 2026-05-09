from abc import abstractmethod
from datetime import date, datetime, time
from typing import List

from app.domain.models.reservation import ReservationEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository
from datetime import datetime, timezone


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

    @abstractmethod
    def list_overlapping_by_charger(
        self,
        charger_id: int,
        reservation_date: date,
        start_time: time,
        end_time: time,
    ) -> List[ReservationEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_overlapping_by_user(
        self,
        user_id: int,
        reservation_date: date,
        start_time: time,
        end_time: time,
    ) -> List[ReservationEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_user_and_date(
        self,
        user_id: int,
        reservation_date: date,
    ) -> List[ReservationEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_user_after_date(
        self,
        user_id: int,
        after_date: date,
    ) -> List[ReservationEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_starting_between(
        self,
        start_datetime: datetime,
        end_datetime: datetime,
    ) -> List[ReservationEntity]:
        raise NotImplementedError

    @abstractmethod
    def get_expired_or_cancelled_count_last_2_months(self, user_id: int) -> int:
        raise NotImplementedError

    @abstractmethod
    def exists_active_for_charger(self, charger_id: int, now: datetime) -> bool:
        raise NotImplementedError