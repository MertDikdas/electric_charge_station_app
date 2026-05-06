from datetime import datetime
from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.payment import PaymentEntity
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

    def get_payment_by_transaction_id(self, transaction_id: str) -> Optional[PaymentEntity]:
        with self.uow:
            return self.uow.payments.get_by_transaction_id(transaction_id)

    def get_user_payments(self, user_id: int) -> List[PaymentEntity]:
        with self.uow:
            if not self.uow.users.get(user_id):
                raise LookupError("User not found")
            return self.uow.payments.list_by_user_id(user_id)

    def get_payments_by_status(self, status: str) -> List[PaymentEntity]:
        with self.uow:
            self.rules.validate_payment_status(status)
            return self.uow.payments.list_by_status(status)

    def get_payment_for_reservation(self, reservation_id: int) -> Optional[PaymentEntity]:
        with self.uow:
            if not self.uow.reservations.get(reservation_id):
                raise LookupError("Reservation not found")
            return self.uow.payments.get_by_reservation_id(reservation_id)

    def update_payment(self, payment: PaymentEntity) -> PaymentEntity:
        with self.uow:
            existing = self.uow.payments.get(payment.id)
            if not existing:
                raise LookupError("Payment not found")

            self.rules.validate_payment_update(payment)

            updated_payment = self.uow.payments.update(payment)
            self.uow.commit()
            return updated_payment

    def complete_payment(self, payment_id: int, transaction_id: str) -> PaymentEntity:
        with self.uow:
            payment = self.uow.payments.get(payment_id)
            if not payment:
                raise LookupError("Payment not found")

            payment.status = "COMPLETED"
            payment.transaction_id = transaction_id
            payment.payment_date = datetime.now()

            updated_payment = self.uow.payments.update(payment)
            self.uow.commit()
            return updated_payment

    def fail_payment(self, payment_id: int, reason: Optional[str] = None) -> PaymentEntity:
        with self.uow:
            payment = self.uow.payments.get(payment_id)
            if not payment:
                raise LookupError("Payment not found")

            payment.status = "FAILED"
            if reason:
                payment.description = reason

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

