from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.reservation_service import (
    ReservationService,
    ReservationConflictError,
)
from app.core.dependencies import (
    AuthenticatedUser,
    ensure_same_company_for_charger,
    get_admin,
    get_company_member,
    get_current_user,
    get_reservation_service,
)
from app.domain.models.reservation import ReservationEntity
from app.schemas.reservation import ReservationCreate, Reservation, ReservationStatusUpdate

router = APIRouter()


@router.post("", response_model=Reservation, status_code=201)
def create_reservation(
    reservation: ReservationCreate,
    service: ReservationService = Depends(get_reservation_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):

    reservation_entity = ReservationEntity(
        **reservation.model_dump(),
        user_id=current_user.id,
        station_id=0
    )
    
    try:
        return service.create_reservation(reservation_entity, current_user.id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ReservationConflictError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/admin/all", response_model=List[Reservation])
def get_reservations(
    service: ReservationService = Depends(get_reservation_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_all_reservations()

@router.get("/my", response_model=List[Reservation])
def get_user_reservations(
    service: ReservationService = Depends(get_reservation_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    return service.get_user_reservations(current_user.id)


@router.get("/{charger_id}", response_model=List[Reservation])
def get_reservations_by_charger(
    charger_id: int,
    service: ReservationService = Depends(get_reservation_service),
    current_user: AuthenticatedUser = Depends(get_company_member),
    membership_check: AuthenticatedUser = Depends(ensure_same_company_for_charger),
):
    try:
        return service.get_reservations_by_charger(charger_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

@router.get("/my/{reservation_id}", response_model=Reservation)
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


@router.delete("/my/{reservation_id}", status_code=204)
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

@router.patch("/my/{reservation_id}/status", response_model=Reservation)
def update_reservation_status(
    reservation_id: int,
    request: ReservationStatusUpdate,
    service: ReservationService = Depends(get_reservation_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    reservation = service.get_reservation(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    if reservation.user_id != current_user.id and not current_user.is_staff:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    try:
        return service.update_reservation_status(
            reservation_id,
            request.status,
            current_user.id,
            current_user.is_staff,
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

## UPDATE ETME EKLENEBİLİR İLERDE
