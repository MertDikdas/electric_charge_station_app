from app.domain.models.charging_session import ChargingSessionCreate, ChargingSession
from app.core.uow import AbstractUnitOfWork
from typing import List

class ChargingSessionService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_session(self, session_in: ChargingSessionCreate) -> ChargingSession:
        with self.uow:
            new_session = ChargingSession(**session_in.model_dump(), id=0)
            self.uow.charging_sessions.add(new_session)
            self.uow.commit()
            return new_session

    def get_all_sessions(self) -> List[ChargingSession]:
        with self.uow:
            return self.uow.charging_sessions.list()
