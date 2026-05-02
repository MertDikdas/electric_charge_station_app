from app.core.uow import AbstractUnitOfWork
from app.domain.models.reservation import ReservationEntity
from typing import List, Optional

class ReservationService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_reservation(self, reservation: ReservationEntity) -> ReservationEntity:
        with self.uow:
            # İleride iş mantığı (business logic) buraya eklenecek.
            # Örneğin: "Bu araç için zaten aktif bir rezervasyon var mı?" 
            # veya "Bu şarj cihazı belirtilen saatlerde dolu mu?" kontrolleri burada yapılır.
            
            new_reservation = self.uow.reservations.add(reservation)
            self.uow.commit()
            return new_reservation

    def get_all_reservations(self) -> List[ReservationEntity]:
        with self.uow:
            return self.uow.reservations.list()

    def get_reservation(self, reservation_id: int) -> Optional[ReservationEntity]:
        with self.uow:
            return self.uow.reservations.get(reservation_id)
