from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class CouponCreate(BaseModel):
    user_id: int
    code: str
    discount_type: str
    discount_value: float
    valid_from: datetime
    valid_until: datetime
    min_order_amount: float = 0.0
    max_discount_amount: Optional[float] = None
    usage_limit: Optional[int] = None
    is_active: bool = True


class Coupon(CouponCreate):
    id: int
    used_count: int


class CouponApplyRequest(BaseModel):
    payment_id: int
    code: str
    order_amount: float


class CouponApplyResult(BaseModel):
    user_id: int
    code: str
    order_amount: float
    discount_amount: float
    final_amount: float
