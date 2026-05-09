from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.charger_service import ChargerService
from app.application.services.reservation_service import ReservationService
from app.core.dependencies import (
    AuthenticatedUser,
    get_admin_or_station_manager,
    get_station_service,
    get_station_manager,
    get_current_user,
    get_current_company_member,
    get_station_operator,
    get_admin,
    ensure_same_company,
    get_company_member,
    get_charger_service,
    get_reservation_service,
)
from app.domain.models.charger import ChargerEntity
from app.schemas.charger import (
    Charger,
    ChargerCreate,
    ChargerPriceUpdate,
    ChargerStatusUpdate,
)
from app.schemas.reservation import Reservation

router = APIRouter()


@router.post("/", response_model=Charger, status_code=201)
def create_charger(
    charger: ChargerCreate,
    service: ChargerService = Depends(get_charger_service),
    _current_user: AuthenticatedUser = Depends(get_station_manager),
):
    charger_entity = ChargerEntity(**charger.model_dump())
    return service.create_charger(charger_entity)


@router.get("/all", response_model=List[Charger])
def get_chargers(service: ChargerService = Depends(get_charger_service)):
    return service.get_all_chargers()


@router.get("/{charger_id}", response_model=Charger)
def get_charger(
    charger_id: int,
    service: ChargerService = Depends(get_charger_service),
):
    charger = service.get_charger(charger_id)
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")
    return charger


@router.put("/{charger_id}", response_model=Charger)
def update_charger(
    charger_id: int,
    charger: ChargerCreate,
    service: ChargerService = Depends(get_charger_service),
    _current_user: AuthenticatedUser = Depends(get_station_manager),
):
    existing_charger = service.get_charger(charger_id)
    if not existing_charger:
        raise HTTPException(status_code=404, detail="Charger not found")
    
    updated_charger = ChargerEntity(
        id=charger_id,
        **charger.model_dump(),
    )
    return service.update_charger(updated_charger)


@router.delete("/{charger_id}", status_code=204)
def delete_charger(
    charger_id: int,
    service: ChargerService = Depends(get_charger_service),
    _current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    charger = service.get_charger(charger_id)
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")
    service.delete_charger(charger_id)


@router.patch("/status/{charger_id}", response_model=Charger)
def update_charger_status(
    charger_id: int,
    status_update: ChargerStatusUpdate,
    service: ChargerService = Depends(get_charger_service),
    _current_user: AuthenticatedUser = Depends(get_company_member),
    _current_user: AuthenticatedUser = Depends(get_company_member),
):
    try:
        charger = service.update_charger_status(charger_id, status_update.status)
        if not charger:
            raise HTTPException(status_code=404, detail="Charger not found")
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return charger


@router.patch("/{charger_id}/price", response_model=Charger)
def update_charger_price(
    charger_id: int,
    price_update: ChargerPriceUpdate,
    service: ChargerService = Depends(get_charger_service),
    _current_user: AuthenticatedUser = Depends(get_station_manager),
):
    try:
        charger = service.update_charger_price(
            charger_id=charger_id,
            price_per_kwh=price_update.price_per_kwh,
        )
        if not charger:
            raise HTTPException(status_code=404, detail="Charger not found")
        return charger
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@router.get("/{charger_id}/reservations", response_model=List[Reservation])
def get_charger_reservations(
    charger_id: int,
    date: str,
    charger_service: ChargerService = Depends(get_charger_service),
    reservation_service: ReservationService = Depends(get_reservation_service),
):
    from datetime import datetime

    charger = charger_service.get_charger(charger_id)
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")

    try:
        reservation_date = datetime.strptime(date, "%d-%m-%Y").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use DD-MM-YYYY")
    
    return reservation_service.get_reservations_by_charger_and_date(charger_id, reservation_date)


@router.get("/{charger_id}/availability")
def get_charger_availability(
    charger_id: int,
    start_date: str,
    end_date: str,
    service: ChargerService = Depends(get_charger_service),
):
    from datetime import datetime

    try:
        start = datetime.strptime(start_date, "%Y-%m-%d").date()
        end = datetime.strptime(end_date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    
    if start > end:
        raise HTTPException(status_code=400, detail="Start date must be before end date")
    
    try:
        return service.get_charger_availability(charger_id, start, end)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
