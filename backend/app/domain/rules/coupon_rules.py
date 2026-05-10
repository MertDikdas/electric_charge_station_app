from datetime import datetime, timezone
import re

from app.domain.models.coupon import CouponEntity

COUPON_CODE_PATTERN = re.compile(r"^[A-Z0-9_-]{3,32}$")


def normalize_coupon_code(code: str) -> str:
    return code.strip().upper()


def validate_coupon_code(code: str) -> bool:
    return bool(COUPON_CODE_PATTERN.fullmatch(normalize_coupon_code(code)))


def validate_coupon_discount(coupon: CouponEntity) -> bool:
    if coupon.discount_type == "PERCENTAGE":
        return 0 < coupon.discount_value <= 100
    if coupon.discount_type == "FIXED_AMOUNT":
        return coupon.discount_value > 0
    return False


def validate_coupon_dates(coupon: CouponEntity) -> bool:
    return coupon.valid_until > coupon.valid_from


def validate_coupon_limits(coupon: CouponEntity) -> bool:
    if coupon.min_order_amount < 0:
        return False
    if coupon.max_discount_amount is not None and coupon.max_discount_amount <= 0:
        return False
    if coupon.usage_limit is not None and coupon.usage_limit <= 0:
        return False
    return coupon.used_count >= 0


def ensure_coupon_is_usable(
    coupon: CouponEntity,
    order_amount: float,
    now: datetime | None = None,
) -> bool:
    current_time = now or datetime.now(timezone.utc)
    valid_from = _to_aware_utc(coupon.valid_from)
    valid_until = _to_aware_utc(coupon.valid_until)

    if not coupon.is_active:
        return False
    if current_time < valid_from or current_time > valid_until:
        return False
    return order_amount >= coupon.min_order_amount


def calculate_coupon_discount(coupon: CouponEntity, order_amount: float) -> float:
    if order_amount <= 0:
        return 0.0

    if coupon.discount_type == "PERCENTAGE":
        discount = order_amount * (coupon.discount_value / 100)
    else:
        discount = coupon.discount_value

    if coupon.max_discount_amount is not None:
        discount = min(discount, coupon.max_discount_amount)

    return round(min(discount, order_amount), 2)


def _to_aware_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)
