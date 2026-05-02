from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.charger_service import ChargerService
from app.core.dependencies import get_charger_service
from app.domain.models.charger import ChargerEntity
from app.schemas.charger import ChargerCreate, Charger

router = APIRouter()


@router.post("/", response_model=Charger, status_code=201)
def create_charger(
    charger: ChargerCreate,
    service: ChargerService = Depends(get_charger_service),
):
    charger_entity = ChargerEntity(**charger.model_dump())
    return service.create_charger(charger_entity)


@router.get("/", response_model=List[Charger])
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
