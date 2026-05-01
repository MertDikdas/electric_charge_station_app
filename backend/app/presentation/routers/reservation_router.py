from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.domain.models.reservation import ReservationCreate, Reservation
from app.core.uow import AbstractUnitOfWork
from app.core.dependencies import get_uow

router = APIRouter()

@router.post("/", response_model=Reservation, status_code=201)
def create_reservation(reservation: ReservationCreate, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        new_reservation = Reservation(**reservation.model_dump(), id=0)
        uow.reservations.add(new_reservation)
        uow.commit()
        return new_reservation

@router.get("/", response_model=List[Reservation])
def get_reservations(uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        return uow.reservations.list()

@router.get("/{reservation_id}", response_model=Reservation)
def get_reservation(reservation_id: int, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        reservation = uow.reservations.get(reservation_id)
        if not reservation:
            raise HTTPException(status_code=404, detail="Reservation not found")
        return reservation
