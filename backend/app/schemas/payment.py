from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class PaymentCreate(BaseModel):
    user_id: int
    reservation_id: int
    amount: float
    status: str = "PENDING"
    coupon_id: Optional[int] = None


class PaymentUpdate(BaseModel):
    amount: Optional[float] = None
    status: Optional[str] = None
    payment_date: Optional[datetime] = None


class Payment(PaymentCreate):
    id: int
    payment_date: Optional[datetime] = None


class PaymentResponse(BaseModel):
    id: int
    user_id: int
    reservation_id: int
    amount: float
    status: str
    payment_date: Optional[datetime]
    coupon_id: Optional[int]

    coupon_code: Optional[str] = None
    discount_amount: float = 0.0
    final_amount: float


class PaymentListResponse(BaseModel):
    total: int
    payments: list[PaymentResponse]
