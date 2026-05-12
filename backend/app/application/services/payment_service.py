from datetime import datetime
from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.payment import PaymentEntity
from app.domain.rules.coupon_rules import (
    calculate_coupon_discount,
    ensure_coupon_is_usable_for_payment,
)
from app.domain.rules.payment_rules import PaymentRules


class PaymentService:

    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow
        self.rules = PaymentRules()

    def create_payment(self, payment: PaymentEntity) -> PaymentEntity:
        with self.uow:
            self.rules.validate_new_payment(payment)

            if not self.uow.users.get(payment.user_id):
                raise LookupError("User not found")

            if not self.uow.reservations.get(payment.reservation_id):
                raise LookupError("Reservation not found")

            if payment.coupon_id and not self.uow.coupons.get(payment.coupon_id):
                raise LookupError("Coupon not found")

            existing_payment = self.uow.payments.get_by_reservation_id(payment.reservation_id)
            if existing_payment:
                raise ValueError("Payment already exists for this reservation")

            new_payment = self.uow.payments.add(payment)
            self.uow.commit()
            return new_payment

    def get_payment(self, payment_id: int) -> Optional[PaymentEntity]:
        with self.uow:
            return self.uow.payments.get(payment_id)

    def get_user_payments(self, user_id: int) -> List[PaymentEntity]:
        with self.uow:
            if not self.uow.users.get(user_id):
                raise LookupError("User not found")
            return self.uow.payments.list_by_user_id(user_id)
        
    def get_user_payments_with_coupon_info(self, user_id: int) -> list[dict]:
        with self.uow:
            if not self.uow.users.get(user_id):
                raise LookupError("User not found")

            payments = self.uow.payments.list_by_user_id(user_id)
            response = []

            for payment in payments:
                coupon_code = None
                discount_amount = 0.0
                final_amount = payment.amount

                if payment.coupon_id is not None:
                    coupon = self.uow.coupons.get(payment.coupon_id)

                    if coupon is not None:
                        coupon_code = coupon.code
                        discount_amount = calculate_coupon_discount(
                            coupon,
                            payment.amount,
                        )
                        final_amount = round(payment.amount - discount_amount, 2)

                response.append(
                    {
                        "id": payment.id,
                        "user_id": payment.user_id,
                        "reservation_id": payment.reservation_id,
                        "amount": payment.amount,
                        "status": payment.status,
                        "payment_date": payment.payment_date,
                        "coupon_id": payment.coupon_id,
                        "coupon_code": coupon_code,
                        "discount_amount": discount_amount,
                        "final_amount": final_amount,
                    }
                )

            return response

    def get_payments_by_status(self, status: str) -> List[PaymentEntity]:
        with self.uow:
            self.rules.validate_payment_status(status)
            return self.uow.payments.list_by_status(status)

    def get_payment_for_charging_session(self, charging_session_id: int) -> Optional[PaymentEntity]:
        with self.uow:
            if not self.uow.charging_sessions.get(charging_session_id):
                raise LookupError("Charging session not found")
            return self.uow.payments.get_by_reservation_id(charging_session_id)

    def update_payment(self, payment: PaymentEntity) -> PaymentEntity:
        with self.uow:
            existing = self.uow.payments.get(payment.id)
            if not existing:
                raise LookupError("Payment not found")

            self.rules.validate_payment_update(payment)

            updated_payment = self.uow.payments.update(payment)
            self.uow.commit()
            return updated_payment

    def complete_payment(self, payment_id: int) -> PaymentEntity:
        with self.uow:
            payment = self.uow.payments.get(payment_id)
            if not payment:
                raise LookupError("Payment not found")
            if payment.status == "COMPLETED":
                return payment

            user = self.uow.users.get(payment.user_id)
            if not user:
                raise LookupError("User not found")

            payable_amount = self._calculate_payable_amount(payment)
            if user.balance < payable_amount:
                raise ValueError("Insufficient balance")

            user.balance = round(user.balance - payable_amount, 2)
            self.uow.users.update(user)

            payment.status = "COMPLETED"
            payment.payment_date = datetime.now()

            updated_payment = self.uow.payments.update(payment)
            self.uow.commit()
            return updated_payment

    def _calculate_payable_amount(self, payment: PaymentEntity) -> float:
        if payment.coupon_id is None:
            return payment.amount

        coupon = self.uow.coupons.get(payment.coupon_id)
        if not coupon:
            raise LookupError("Coupon not found")
        if coupon.user_id != payment.user_id:
            raise ValueError("Coupon does not belong to payment user")
        if not ensure_coupon_is_usable_for_payment(coupon, payment.amount):
            raise ValueError("Coupon is not usable for this payment")

        discount_amount = calculate_coupon_discount(coupon, payment.amount)
        self.uow.coupons.update(coupon)

        return round(payment.amount - discount_amount, 2)

    def fail_payment(self, payment_id: int) -> PaymentEntity:
        with self.uow:
            payment = self.uow.payments.get(payment_id)
            if not payment:
                raise LookupError("Payment not found")

            payment.status = "FAILED"

            updated_payment = self.uow.payments.update(payment)
            self.uow.commit()
            return updated_payment

    def refund_payment(self, payment_id: int) -> PaymentEntity:
        with self.uow:
            payment = self.uow.payments.get(payment_id)
            if not payment:
                raise LookupError("Payment not found")

            self.rules.validate_refund(payment)

            payment.status = "REFUNDED"
            updated_payment = self.uow.payments.update(payment)
            self.uow.commit()
            return updated_payment

    def delete_payment(self, payment_id: int) -> bool:
        with self.uow:
            payment = self.uow.payments.get(payment_id)
            if not payment:
                return False
            self.uow.payments.delete(payment)
            self.uow.commit()
            return True

    def remove_coupon(self, payment_id: int) -> PaymentEntity:
        with self.uow:
            payment = self.uow.payments.get(payment_id)
            if not payment:
                raise LookupError("Payment not found")
            coupon = self.uow.coupons.get(payment.coupon_id)
            payment.coupon_id = None
            if coupon.used_count >0:
                coupon.used_count -= coupon.used_count
            payment = self.uow.payments.update(payment)
            self.uow.coupons.update(coupon)
            self.uow.commit()
            return payment
