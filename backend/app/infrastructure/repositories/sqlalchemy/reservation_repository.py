from datetime import date, time
from typing import List

from app.domain.models.reservation import ReservationEntity
from app.infrastructure.database.tables import Reservation as ReservationModel
from app.infrastructure.repositories.abstract.reservation_repository import (
    AbstractReservationRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyReservationRepository(
    SqlAlchemyRepository[ReservationEntity, ReservationModel],
    AbstractReservationRepository,
):
    model = ReservationModel
    blocking_statuses = ("PENDING", "CONFIRMED")

    def to_model(self, entity: ReservationEntity) -> ReservationModel:
        return ReservationModel(
            id=entity.id,
            user_id=entity.user_id,
            vehicle_id=entity.vehicle_id,
            charger_id=entity.charger_id,
            date=entity.date,
            start_time=entity.start_time,
            end_time=entity.end_time,
            status=entity.status.upper(),
        )

    def to_entity(self, model: ReservationModel) -> ReservationEntity:
        return ReservationEntity(
            id=model.id,
            user_id=model.user_id,
            vehicle_id=model.vehicle_id,
            charger_id=model.charger_id,
            date=model.date,
            start_time=model.start_time,
            end_time=model.end_time,
            status=model.status,
        )

    def list_by_user(self, user_id: int) -> List[ReservationEntity]:
        models = (
            self.session.query(ReservationModel)
            .filter(ReservationModel.user_id == user_id)
            .all()
        )
        return [self.to_entity(model) for model in models]

    def list_by_charger_and_date(
        self,
        charger_id: int,
        reservation_date: date,
    ) -> List[ReservationEntity]:
        models = (
            self.session.query(ReservationModel)
            .filter(
                ReservationModel.charger_id == charger_id,
                ReservationModel.date == reservation_date,
            )
            .all()
        )
        return [self.to_entity(model) for model in models]

    def list_by_user_id(self, user_id: int) -> List[ReservationEntity]:
        models = (
            self.session.query(ReservationModel)
            .filter(ReservationModel.user_id == user_id)
            .all()
        )
        return [self.to_entity(model) for model in models]

    def list_overlapping_by_charger(
        self,
        charger_id: int,
        reservation_date: date,
        start_time: time,
        end_time: time,
    ) -> List[ReservationEntity]:
        models = (
            self.session.query(ReservationModel)
            .filter(
                ReservationModel.charger_id == charger_id,
                ReservationModel.date == reservation_date,
                ReservationModel.status.in_(self.blocking_statuses),
                ReservationModel.start_time < end_time,
                ReservationModel.end_time > start_time,
            )
            .all()
        )
        return [self.to_entity(model) for model in models]

    def list_overlapping_by_user(
        self,
        user_id: int,
        reservation_date: date,
        start_time: time,
        end_time: time,
    ) -> List[ReservationEntity]:
        models = (
            self.session.query(ReservationModel)
            .filter(
                ReservationModel.user_id == user_id,
                ReservationModel.date == reservation_date,
                ReservationModel.status.in_(self.blocking_statuses),
                ReservationModel.start_time < end_time,
                ReservationModel.end_time > start_time,
            )
            .all()
        )
        return [self.to_entity(model) for model in models]
