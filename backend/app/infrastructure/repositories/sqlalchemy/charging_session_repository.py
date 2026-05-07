from datetime import datetime

from app.domain.models.charging_session import (
    ChargingSessionEntity,
    ExpiredChargingSessionForAutoFinish,
)
from app.infrastructure.database.tables import (
    ChargingSession as ChargingSessionModel,
    Reservation as ReservationModel,
)
from app.infrastructure.repositories.abstract.charging_session_repository import (
    AbstractChargingSessionRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyChargingSessionRepository(
    SqlAlchemyRepository[ChargingSessionEntity, ChargingSessionModel],
    AbstractChargingSessionRepository,
):
    model = ChargingSessionModel
    active_statuses = ("STARTED", "IN_PROGRESS")

    def to_model(self, entity: ChargingSessionEntity) -> ChargingSessionModel:
        return ChargingSessionModel(
            reservation_id=entity.reservation_id,
            start_time=entity.start_time,
            end_time=entity.end_time,
            consuming_power=entity.consuming_power,
            cost=entity.cost,
            status=entity.status.upper(),
        )

    def to_entity(self, model: ChargingSessionModel) -> ChargingSessionEntity:
        return ChargingSessionEntity(
            id=model.reservation_id,
            reservation_id=model.reservation_id,
            start_time=model.start_time,
            end_time=model.end_time,
            consuming_power=model.consuming_power,
            cost=model.cost,
            status=model.status,
        )

    def list_by_user_id(self, user_id: int) -> list[ChargingSessionEntity]:
        query = self.session.query(self.model).join(self.model.reservation).filter(
            self.model.reservation.has(user_id=user_id)
        )
        return [self.to_entity(model) for model in query.all()]

    def list_by_charger_id(self, charger_id: int) -> list[ChargingSessionEntity]:
        query = self.session.query(self.model).join(self.model.reservation).filter(
            self.model.reservation.has(charger_id=charger_id)
        )
        return [self.to_entity(model) for model in query.all()]

    def list_active_by_user_id(self, user_id: int) -> list[ChargingSessionEntity]:
        query = (
            self.session.query(self.model)
            .join(self.model.reservation)
            .filter(
                self.model.reservation.has(user_id=user_id),
                self.model.status.in_(self.active_statuses),
            )
        )
        return [self.to_entity(model) for model in query.all()]

    def list_active_by_charger_id(self, charger_id: int) -> list[ChargingSessionEntity]:
        query = (
            self.session.query(self.model)
            .join(self.model.reservation)
            .filter(
                self.model.reservation.has(charger_id=charger_id),
                self.model.status.in_(self.active_statuses),
            )
        )
        return [self.to_entity(model) for model in query.all()]

    def list_expired_for_auto_finish(
        self,
        current_datetime: datetime,
    ) -> list[ExpiredChargingSessionForAutoFinish]:
        rows = (
            self.session.query(
                ChargingSessionModel.reservation_id,
                ReservationModel.user_id,
                ReservationModel.end_time,
            )
            .join(ReservationModel, ChargingSessionModel.reservation)
            .filter(
                ChargingSessionModel.status.in_(self.active_statuses),
                ChargingSessionModel.end_time.is_(None),
                ReservationModel.date == current_datetime.date(),
                ReservationModel.end_time <= current_datetime.time(),
                ReservationModel.status.in_(("PENDING", "CONFIRMED")),
            )
            .all()
        )
        return [
            ExpiredChargingSessionForAutoFinish(
                reservation_id=reservation_id,
                user_id=user_id,
                end_time=end_time,
            )
            for reservation_id, user_id, end_time in rows
        ]
