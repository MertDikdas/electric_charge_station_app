from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.coupon import CouponEntity
from app.domain.rules.coupon_rules import (
    calculate_coupon_discount,
    ensure_coupon_is_usable,
    normalize_coupon_code,
    validate_coupon_code,
    validate_coupon_dates,
    validate_coupon_discount,
    validate_coupon_limits,
)


class CouponService:
    allowed_discount_types = {"PERCENTAGE", "FIXED_AMOUNT"}

    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_coupon(self, coupon: CouponEntity) -> CouponEntity:
        with self.uow:
            coupon.code = normalize_coupon_code(coupon.code)
            coupon.discount_type = coupon.discount_type.upper()
            self._validate_coupon(coupon)

            if not self.uow.users.get(coupon.user_id):
                raise LookupError("User not found")

            if self.uow.coupons.get_by_user_and_code(coupon.user_id, coupon.code):
                raise ValueError("Coupon code already exists for this user")

            new_coupon = self.uow.coupons.add(coupon)
            self.uow.commit()
            return new_coupon

    def get_all_coupons(self) -> List[CouponEntity]:
        with self.uow:
            return self.uow.coupons.list()

    def get_coupon(self, coupon_id: int) -> Optional[CouponEntity]:
        with self.uow:
            return self.uow.coupons.get(coupon_id)

    def get_user_coupons(self, user_id: int) -> List[CouponEntity]:
        with self.uow:
            return self.uow.coupons.list_by_user(user_id)

    def get_user_coupon_by_code(
        self,
        user_id: int,
        code: str,
    ) -> Optional[CouponEntity]:
        with self.uow:
            return self.uow.coupons.get_by_user_and_code(
                user_id,
                normalize_coupon_code(code),
            )

    def delete_coupon(self, coupon_id: int) -> bool:
        with self.uow:
            coupon = self.uow.coupons.get(coupon_id)
            if not coupon:
                return False
            self.uow.coupons.delete(coupon)
            self.uow.commit()
            return True

    def preview_discount(self, user_id: int, payment_id: int, code: str, order_amount: float) -> dict:
        with self.uow:
            coupon = self.uow.coupons.get_by_user_and_code(
            user_id,
            normalize_coupon_code(code),)
            payment = self.uow.payments.get(payment_id)
            if coupon.used_count >= coupon.usage_limit and payment.coupon_id!=coupon.id:
                raise ValueError("Coupon reached the usage limit.")
            discount_amount = calculate_coupon_discount(coupon, order_amount)
            return self._build_discount_result(coupon, order_amount, discount_amount)

    def apply_coupon(self, user_id: int, payment_id: int, code: str, order_amount: float) -> dict:
        with self.uow:
            payment = self.uow.payments.get(payment_id)
            if not payment:
                raise ValueError("Can't find a payment")
            coupon = self._get_usable_coupon(user_id, code, order_amount)
            if not ensure_coupon_is_usable:
                raise ValueError("Coupon is not usable for this order")
            if payment.amount != order_amount:
                raise ValueError("The amount different from payment amount.")
            discount_amount = calculate_coupon_discount(coupon, order_amount)
            coupon.used_count += 1
            payment.coupon_id = coupon.id
            self.uow.payments.update(payment)
            self.uow.coupons.update(coupon)
            self.uow.commit()
            return self._build_discount_result(coupon, order_amount, discount_amount)

    def _get_usable_coupon(
        self,
        user_id: int,
        code: str,
        order_amount: float,
    ) -> CouponEntity:
        if order_amount <= 0:
            raise ValueError("Order amount must be greater than 0")

        coupon = self.uow.coupons.get_by_user_and_code(
            user_id,
            normalize_coupon_code(code),
        )
        if not coupon:
            raise LookupError("Coupon not found")

        if not ensure_coupon_is_usable(coupon, order_amount):
            raise ValueError("Coupon is not usable for this order")

        return coupon

    def _validate_coupon(self, coupon: CouponEntity) -> None:
        if not validate_coupon_code(coupon.code):
            raise ValueError("Coupon code must be 3-32 characters and contain only uppercase letters, numbers, underscores, or hyphens")
        if coupon.discount_type not in self.allowed_discount_types:
            raise ValueError("Coupon discount_type must be PERCENTAGE or FIXED_AMOUNT")
        if not validate_coupon_discount(coupon):
            raise ValueError("Coupon discount value is invalid")
        if not validate_coupon_dates(coupon):
            raise ValueError("Coupon valid_until must be after valid_from")
        if not validate_coupon_limits(coupon):
            raise ValueError("Coupon limits are invalid")

    def _build_discount_result(
        self,
        coupon: CouponEntity,
        order_amount: float,
        discount_amount: float,
    ) -> dict:
        return {
            "user_id": coupon.user_id,
            "code": coupon.code,
            "order_amount": round(order_amount, 2),
            "discount_amount": discount_amount,
            "final_amount": round(order_amount - discount_amount, 2),
        }
