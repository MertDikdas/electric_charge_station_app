from app.infrastructure.database.tables import ChargingSession
from app.infrastructure.repositories.abstract.charging_session_repository import (
    AbstractChargingSessionRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyChargingSessionRepository(
    SqlAlchemyRepository[ChargingSession],
    AbstractChargingSessionRepository,
):
    model = ChargingSession
