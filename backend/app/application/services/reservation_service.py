from app.models.reservation import ReservationCreate, Reservation
from app.core.uow import AbstractUnitOfWork
from typing import List, Optional

class ReservationService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_reservation(self, reservation_in: ReservationCreate) -> Reservation:
        with self.uow:
            # İleride iş mantığı (business logic) buraya eklenecek.
            # Örneğin: "Bu araç için zaten aktif bir rezervasyon var mı?" 
            # veya "Bu şarj cihazı belirtilen saatlerde dolu mu?" kontrolleri burada yapılır.
            
            new_reservation = Reservation(**reservation_in.model_dump(), id=0)
            self.uow.reservations.add(new_reservation)
            self.uow.commit()
            return new_reservation

    def get_all_reservations(self) -> List[Reservation]:
        with self.uow:
            return self.uow.reservations.list()

    def get_reservation(self, reservation_id: int) -> Optional[Reservation]:
        with self.uow:
            return self.uow.reservations.get(reservation_id)
