from typing import List, Optional

from app.domain.models.coupon import CouponEntity
from app.infrastructure.database.tables import Coupon as CouponModel
from app.infrastructure.repositories.abstract.coupon_repository import (
    AbstractCouponRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyCouponRepository(
    SqlAlchemyRepository[CouponEntity, CouponModel],
    AbstractCouponRepository,
):
    model = CouponModel

    def to_model(self, entity: CouponEntity) -> CouponModel:
        return CouponModel(
            id=entity.id,
            user_id=entity.user_id,
            code=entity.code,
            discount_type=entity.discount_type,
            discount_value=entity.discount_value,
            min_order_amount=entity.min_order_amount,
            max_discount_amount=entity.max_discount_amount,
            valid_from=entity.valid_from,
            valid_until=entity.valid_until,
            usage_limit=entity.usage_limit,
            used_count=entity.used_count,
            is_active=entity.is_active,
        )

    def to_entity(self, model: CouponModel) -> CouponEntity:
        return CouponEntity(
            id=model.id,
            user_id=model.user_id,
            code=model.code,
            discount_type=model.discount_type,
            discount_value=model.discount_value,
            min_order_amount=model.min_order_amount,
            max_discount_amount=model.max_discount_amount,
            valid_from=model.valid_from,
            valid_until=model.valid_until,
            usage_limit=model.usage_limit,
            used_count=model.used_count,
            is_active=model.is_active,
        )

    def get_by_user_and_code(self, user_id: int, code: str) -> Optional[CouponEntity]:
        model = (
            self.session.query(CouponModel)
            .filter(
                CouponModel.user_id == user_id,
                CouponModel.code == code,
            )
            .first()
        )
        if model is None:
            return None
        return self.to_entity(model)

    def list_by_user(self, user_id: int) -> List[CouponEntity]:
        models = (
            self.session.query(CouponModel)
            .filter(CouponModel.user_id == user_id)
            .all()
        )
        return [self.to_entity(model) for model in models]

    def update(self, coupon: CouponEntity) -> CouponEntity:
        model = self.session.get(CouponModel, coupon.id)
        if model is None:
            raise LookupError("Coupon not found")

        model.code = coupon.code
        model.user_id = coupon.user_id
        model.discount_type = coupon.discount_type
        model.discount_value = coupon.discount_value
        model.min_order_amount = coupon.min_order_amount
        model.max_discount_amount = coupon.max_discount_amount
        model.valid_from = coupon.valid_from
        model.valid_until = coupon.valid_until
        model.usage_limit = coupon.usage_limit
        model.used_count = coupon.used_count
        model.is_active = coupon.is_active
        self.session.flush()
        return self.to_entity(model)
