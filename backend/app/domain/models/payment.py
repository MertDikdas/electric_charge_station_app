from dataclasses import dataclass
from datetime import datetime
from typing import Optional

from app.domain.models.base import BaseEntity


@dataclass
class PaymentEntity(BaseEntity):
    user_id: int
    reservation_id: int
    amount: float
    payment_method: str
    status: str
    transaction_id: Optional[str] = None
    payment_date: Optional[datetime] = None
    description: Optional[str] = None
    coupon_id: Optional[int] = None
    original_amount: Optional[float] = None


Payment = PaymentEntity
