from app.core.uow import AbstractUnitOfWork
from app.domain.models.charger import ChargerEntity
from typing import List, Optional

class ChargerService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_charger(self, charger: ChargerEntity) -> ChargerEntity:
        with self.uow:
            new_charger = self.uow.chargers.add(charger)
            self.uow.commit()
            return new_charger

    def get_all_chargers(self) -> List[ChargerEntity]:
        with self.uow:
            return self.uow.chargers.list()

    def get_charger(self, charger_id: int) -> Optional[ChargerEntity]:
        with self.uow:
            return self.uow.chargers.get(charger_id)
