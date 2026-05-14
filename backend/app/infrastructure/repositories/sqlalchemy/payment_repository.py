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
            reservation_id=entity.reservation_id,
            amount=entity.amount,
            status=entity.status,
            payment_date=entity.payment_date,
            coupon_id=entity.coupon_id,
        )

    def to_entity(self, model: PaymentModel) -> PaymentEntity:
        return PaymentEntity(
            id=model.id,
            user_id=model.user_id,
            reservation_id=model.reservation_id,
            amount=model.amount,
            status=model.status,
            payment_date=model.payment_date,
            coupon_id=model.coupon_id,
            final_amount= model.amount
        )

    def get_by_user_id(self, user_id: int) -> List[PaymentEntity]:
        models = (
            self.session.query(PaymentModel)
            .filter(PaymentModel.user_id == user_id)
            .all()
        )
        return [self.to_entity(model) for model in models]

    def get_by_reservation_id(self, reservation_id: int) -> Optional[PaymentEntity]:
        model = (
            self.session.query(PaymentModel)
            .filter(PaymentModel.reservation_id == reservation_id)
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
        model.reservation_id = payment.reservation_id
        model.amount = payment.amount
        model.status = payment.status
        model.payment_date = payment.payment_date
        model.coupon_id = payment.coupon_id
        self.session.flush()
        return self.to_entity(model)
