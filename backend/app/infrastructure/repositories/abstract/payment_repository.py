from abc import abstractmethod
from typing import List, Optional

from app.domain.models.payment import PaymentEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractPaymentRepository(AbstractRepository[PaymentEntity]):
    @abstractmethod
    def get_by_user_id(self, user_id: int) -> List[PaymentEntity]:
        raise NotImplementedError

    @abstractmethod
    def get_by_reservation_id(self, charging_session_id: int) -> Optional[PaymentEntity]:
        raise NotImplementedError

    @abstractmethod
    def get_by_transaction_id(self, transaction_id: str) -> Optional[PaymentEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_user_id(self, user_id: int) -> List[PaymentEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_status(self, status: str) -> List[PaymentEntity]:
        raise NotImplementedError

    @abstractmethod
    def update(self, payment: PaymentEntity) -> PaymentEntity:
        raise NotImplementedError
