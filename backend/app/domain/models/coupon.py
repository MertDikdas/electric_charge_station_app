from dataclasses import dataclass
from datetime import datetime
from typing import Optional

from app.domain.models.base import BaseEntity


@dataclass
class CouponEntity(BaseEntity):
    user_id: int
    code: str
    discount_type: str
    discount_value: float
    valid_from: datetime
    valid_until: datetime
    min_order_amount: float = 0.0
    max_discount_amount: Optional[float] = None
    usage_limit: Optional[int] = None
    used_count: int = 0
    is_active: bool = True


Coupon = CouponEntity
