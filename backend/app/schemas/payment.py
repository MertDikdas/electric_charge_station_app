from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class PaymentCreate(BaseModel):
    user_id: int
    charging_session_id: int
    amount: float
    payment_method: str
    status: str = "PENDING"
    transaction_id: Optional[str] = None
    description: Optional[str] = None
    coupon_id: Optional[int] = None
    original_amount: Optional[float] = None


class PaymentUpdate(BaseModel):
    amount: Optional[float] = None
    status: Optional[str] = None
    transaction_id: Optional[str] = None
    payment_date: Optional[datetime] = None
    description: Optional[str] = None


class Payment(PaymentCreate):
    id: int
    payment_date: Optional[datetime] = None


class PaymentResponse(BaseModel):
    id: int
    user_id: int
    charging_session_id: int
    amount: float
    payment_method: str
    status: str
    transaction_id: Optional[str]
    payment_date: Optional[datetime]
    description: Optional[str]
    coupon_id: Optional[int]
    original_amount: Optional[float]


class PaymentListResponse(BaseModel):
    total: int
    payments: list[PaymentResponse]
