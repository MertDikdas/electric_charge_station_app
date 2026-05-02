from datetime import date
from typing import List

from app.infrastructure.database.tables import Reservation
from app.infrastructure.repositories.abstract.reservation_repository import (
    AbstractReservationRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyReservationRepository(
    SqlAlchemyRepository[Reservation],
    AbstractReservationRepository,
):
    model = Reservation

    def list_by_user(self, user_id: int) -> List[Reservation]:
        return self.session.query(Reservation).filter(Reservation.user_id == user_id).all()

    def list_by_charger_and_date(
        self,
        charger_id: int,
        reservation_date: date,
    ) -> List[Reservation]:
        return (
            self.session.query(Reservation)
            .filter(
                Reservation.charger_id == charger_id,
                Reservation.date == reservation_date,
            )
            .all()
        )
