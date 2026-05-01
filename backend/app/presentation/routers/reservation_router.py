from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.reservation_service import ReservationService
from app.core.dependencies import get_reservation_service
from app.schemas.reservation import ReservationCreate, Reservation

router = APIRouter()


@router.post("/", response_model=Reservation, status_code=201)
def create_reservation(
    reservation: ReservationCreate,
    service: ReservationService = Depends(get_reservation_service),
):
    return service.create_reservation(reservation)


@router.get("/", response_model=List[Reservation])
def get_reservations(service: ReservationService = Depends(get_reservation_service)):
    return service.get_all_reservations()


@router.get("/{reservation_id}", response_model=Reservation)
def get_reservation(
    reservation_id: int,
    service: ReservationService = Depends(get_reservation_service),
):
    reservation = service.get_reservation(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    return reservation
