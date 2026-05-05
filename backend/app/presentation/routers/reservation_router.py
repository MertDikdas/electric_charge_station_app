from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.reservation_service import ReservationService
from app.core.dependencies import (
    AuthenticatedUser,
    get_admin_or_station_manager,
    get_current_user,
    get_reservation_service,
)
from app.domain.models.reservation import ReservationEntity
from app.schemas.reservation import ReservationCreate, Reservation

router = APIRouter()

def ensure_admin_role(current_user: AuthenticatedUser) -> None:
    if current_user.role.lower() != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")

def ensure_authenticated(current_user: AuthenticatedUser) -> None:
    if not current_user.is_authenticated and current_user.role.lower() != "admin":
        raise HTTPException(status_code=401, detail="Authentication required")

@router.post("", response_model=Reservation, status_code=201)
def create_reservation(
    reservation: ReservationCreate,
    service: ReservationService = Depends(get_reservation_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    reservation_entity = ReservationEntity(
        **reservation.model_dump(),
        user_id=current_user.id
    )
    try:
        return service.create_reservation(reservation_entity, current_user.id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("", response_model=List[Reservation])
def get_reservations(
    service: ReservationService = Depends(get_reservation_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    ensure_admin_role(current_user)
    return service.get_all_reservations()


@router.get("/{reservation_id}", response_model=Reservation)
def get_reservation(
    reservation_id: int,
    service: ReservationService = Depends(get_reservation_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    reservation = service.get_reservation(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    if reservation.user_id != current_user.id and not current_user.is_staff:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return reservation


@router.delete("/{reservation_id}", status_code=204)
def delete_reservation(
    reservation_id: int,
    service: ReservationService = Depends(get_reservation_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    reservation = service.get_reservation(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    if reservation.user_id != current_user.id and not current_user.is_staff:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    service.delete_reservation(reservation_id)


## UPDATE ETME EKLENEBİLİR İLERDE