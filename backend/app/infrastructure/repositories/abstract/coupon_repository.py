from abc import abstractmethod
from typing import List, Optional

from app.domain.models.coupon import CouponEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractCouponRepository(AbstractRepository[CouponEntity]):
    @abstractmethod
    def get_by_user_and_code(self, user_id: int, code: str) -> Optional[CouponEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_user(self, user_id: int) -> List[CouponEntity]:
        raise NotImplementedError

    @abstractmethod
    def update(self, coupon: CouponEntity) -> CouponEntity:
        raise NotImplementedError
