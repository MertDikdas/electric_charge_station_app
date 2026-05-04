from typing import List, Optional

from app.domain.models.payment import PaymentEntity
from app.infrastructure.database.tables import Payment as PaymentModel
from app.infrastructure.repositories.abstract.payment_repository import (
    AbstractPaymentRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyPaymentRepository(
    SqlAlchemyRepository[PaymentEntity, PaymentModel],
    AbstractPaymentRepository,
):
    model = PaymentModel

    def to_model(self, entity: PaymentEntity) -> PaymentModel:
        return PaymentModel(
            id=entity.id,
            user_id=entity.user_id,
            charging_session_id=entity.charging_session_id,
            amount=entity.amount,
            payment_method=entity.payment_method,
            status=entity.status,
            transaction_id=entity.transaction_id,
            payment_date=entity.payment_date,
            description=entity.description,
            coupon_id=entity.coupon_id,
            original_amount=entity.original_amount,
        )

    def to_entity(self, model: PaymentModel) -> PaymentEntity:
        return PaymentEntity(
            id=model.id,
            user_id=model.user_id,
            charging_session_id=model.charging_session_id,
            amount=model.amount,
            payment_method=model.payment_method,
            status=model.status,
            transaction_id=model.transaction_id,
            payment_date=model.payment_date,
            description=model.description,
            coupon_id=model.coupon_id,
            original_amount=model.original_amount,
        )

    def get_by_user_id(self, user_id: int) -> List[PaymentEntity]:
        models = (
            self.session.query(PaymentModel)
            .filter(PaymentModel.user_id == user_id)
            .all()
        )
        return [self.to_entity(model) for model in models]

    def get_by_charging_session_id(self, charging_session_id: int) -> Optional[PaymentEntity]:
        model = (
            self.session.query(PaymentModel)
            .filter(PaymentModel.charging_session_id == charging_session_id)
            .first()
        )
        if model is None:
            return None
        return self.to_entity(model)

    def get_by_transaction_id(self, transaction_id: str) -> Optional[PaymentEntity]:
        model = (
            self.session.query(PaymentModel)
            .filter(PaymentModel.transaction_id == transaction_id)
            .first()
        )
        if model is None:
            return None
        return self.to_entity(model)

    def list_by_user_id(self, user_id: int) -> List[PaymentEntity]:
        models = (
            self.session.query(PaymentModel)
            .filter(PaymentModel.user_id == user_id)
            .order_by(PaymentModel.payment_date.desc())
            .all()
        )
        return [self.to_entity(model) for model in models]

    def list_by_status(self, status: str) -> List[PaymentEntity]:
        models = (
            self.session.query(PaymentModel)
            .filter(PaymentModel.status == status)
            .all()
        )
        return [self.to_entity(model) for model in models]

    def update(self, payment: PaymentEntity) -> PaymentEntity:
        model = self.session.get(PaymentModel, payment.id)
        if model is None:
            raise LookupError("Payment not found")

        model.user_id = payment.user_id
        model.charging_session_id = payment.charging_session_id
        model.amount = payment.amount
        model.payment_method = payment.payment_method
        model.status = payment.status
        model.transaction_id = payment.transaction_id
        model.payment_date = payment.payment_date
        model.description = payment.description
        model.coupon_id = payment.coupon_id
        model.original_amount = payment.original_amount
        self.session.flush()
        return self.to_entity(model)
