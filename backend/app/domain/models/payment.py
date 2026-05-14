from dataclasses import dataclass
from datetime import datetime
from typing import Optional

from app.domain.models.base import BaseEntity


@dataclass
class PaymentEntity(BaseEntity):
    user_id: int
    reservation_id: int
    amount: float
    status: str
    payment_date: Optional[datetime] = None
    coupon_id: Optional[int] = None
    final_amount: Optional[float] = None

Payment = PaymentEntity
