from datetime import date, datetime, timedelta, time, timezone
from typing import List

from sqlalchemy import and_, or_, func

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
            station_id=entity.station_id,
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
            station_id=model.station_id,
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

    def list_by_user_and_date(
        self,
        user_id: int,
        reservation_date: date,
    ) -> List[ReservationEntity]:
        models = (
            self.session.query(ReservationModel)
            .filter(
                ReservationModel.user_id == user_id,
                ReservationModel.date == reservation_date,
                ReservationModel.status.in_(self.blocking_statuses),
            )
            .all()
        )
        return [self.to_entity(model) for model in models]
    def list_by_user_after_date(
        self,
        user_id: int,
        after_date: date,
    ) -> List[ReservationEntity]:
        models = (
            self.session.query(ReservationModel)
            .filter(
                ReservationModel.user_id == user_id,
                ReservationModel.date > after_date,
            )
            .all()
        )
        return [self.to_entity(model) for model in models]

    def list_starting_between(
        self,
        start_datetime: datetime,
        end_datetime: datetime,
    ) -> List[ReservationEntity]:
        start_date = start_datetime.date()
        end_date = end_datetime.date()
        if start_date == end_date:
            models = (
                self.session.query(ReservationModel)
                .filter(
                    ReservationModel.status.in_(self.blocking_statuses),
                    ReservationModel.date == start_date,
                    ReservationModel.start_time >= start_datetime.time(),
                    ReservationModel.start_time < end_datetime.time(),
                )
                .all()
            )
        else:
            models = (
                self.session.query(ReservationModel)
                .filter(
                    ReservationModel.status.in_(self.blocking_statuses),
                    or_(
                        and_(
                            ReservationModel.date == start_date,
                            ReservationModel.start_time >= start_datetime.time(),
                        ),
                        and_(
                            ReservationModel.date == end_date,
                            ReservationModel.start_time < end_datetime.time(),
                        ),
                    ),
                )
                .all()
            )
        return [self.to_entity(model) for model in models]

    def get_expired_or_cancelled_count_last_2_months(self, user_id: int) -> int:
        two_months_ago = datetime.utcnow().date() - timedelta(days=60)
        return (
            self.session.query(ReservationModel)
            .filter(
                ReservationModel.user_id == user_id,
                ReservationModel.status.in_(["EXPIRED", "CANCELLED"]),
                ReservationModel.date >= two_months_ago,
            )
            .count()
        )

    def exists_active_for_charger(self, charger_id: int, now: datetime) -> bool:
        today = now.date()
        current_time = now.time().replace(tzinfo=None, microsecond=0)

        active_reservation = (
            self.session.query(ReservationModel)
            .filter(
                ReservationModel.charger_id == charger_id,
                ReservationModel.date == today,
                ReservationModel.start_time <= current_time,
                ReservationModel.end_time >= current_time,
                func.upper(ReservationModel.status).notin_([
                    "CANCELLED",
                    "COMPLETED",
                    "FAILED",
                ]),
            )
            .first()
        )

        print(
            "CHECK RESERVATION:",
            "charger_id=", charger_id,
            "today=", today,
            "time=", current_time,
            "found=", active_reservation is not None,
        )

        return active_reservation is not None

    def list_active_for_chargers(
        self,
        charger_ids: list[int],
        now: datetime,
    ) -> List[ReservationEntity]:
        if not charger_ids:
            return []

        today = now.date()
        current_time = now.time().replace(tzinfo=None, microsecond=0)

        models = (
            self.session.query(ReservationModel)
            .filter(
                ReservationModel.charger_id.in_(charger_ids),
                ReservationModel.status.in_(self.blocking_statuses),
                or_(
                    ReservationModel.date > today,
                    and_(
                        ReservationModel.date == today,
                        ReservationModel.end_time >= current_time,
                    ),
                ),
            )
            .all()
        )
        return [self.to_entity(model) for model in models]
    
    def delete_upcoming_by_user_id(self, user_id: int) -> None:
        now = datetime.now()
        today = now.date()
        current_time = now.time()

        self.session.query(ReservationModel).filter(
            ReservationModel.user_id == user_id,
            (
                (ReservationModel.date > today)
                | (
                    (ReservationModel.date == today)
                    & (ReservationModel.start_time > current_time)
                )
            ),
        ).delete(
            synchronize_session=False,
        )
