from app.domain.models.payment import PaymentEntity


class PaymentRules:
    allowed_payment_methods = {"CREDIT_CARD", "DEBIT_CARD", "BANK_TRANSFER", "MOBILE_PAYMENT", "WALLET"}
    allowed_payment_statuses = {"PENDING", "COMPLETED", "FAILED", "REFUNDED"}

    def validate_new_payment(self, payment: PaymentEntity) -> None:
        if payment.amount <= 0:
            raise ValueError("Payment amount must be greater than 0")
        self.validate_payment_method(payment.payment_method)
        self.validate_payment_status(payment.status)

    def validate_payment_update(self, payment: PaymentEntity) -> None:
        if payment.status is not None:
            self.validate_payment_status(payment.status)
        if payment.payment_method is not None:
            self.validate_payment_method(payment.payment_method)

    def validate_payment_status(self, status: str) -> None:
        if status not in self.allowed_payment_statuses:
            raise ValueError(f"Invalid payment status: {status}")

    def validate_payment_method(self, payment_method: str) -> None:
        if payment_method not in self.allowed_payment_methods:
            raise ValueError(f"Invalid payment method: {payment_method}")

    def validate_refund(self, payment: PaymentEntity) -> None:
        if payment.status not in {"COMPLETED", "PENDING"}:
            raise ValueError(f"Cannot refund payment with status: {payment.status}")
