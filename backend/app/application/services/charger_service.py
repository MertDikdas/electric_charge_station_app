from app.domain.models.charger import ChargerCreate, Charger
from app.core.uow import AbstractUnitOfWork
from typing import List, Optional

class ChargerService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_charger(self, charger_in: ChargerCreate) -> Charger:
        with self.uow:
            new_charger = Charger(**charger_in.model_dump(), id=0)
            self.uow.chargers.add(new_charger)
            self.uow.commit()
            return new_charger

    def get_all_chargers(self) -> List[Charger]:
        with self.uow:
            return self.uow.chargers.list()

    def get_charger(self, charger_id: int) -> Optional[Charger]:
        with self.uow:
            return self.uow.chargers.get(charger_id)
