from app.core.uow import AbstractUnitOfWork
from app.domain.models.charging_session import ChargingSessionEntity
from typing import List

class ChargingSessionService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_session(self, session: ChargingSessionEntity) -> ChargingSessionEntity:
        with self.uow:
            new_session = self.uow.charging_sessions.add(session)
            self.uow.commit()
            return new_session

    def get_all_sessions(self) -> List[ChargingSessionEntity]:
        with self.uow:
            return self.uow.charging_sessions.list()
