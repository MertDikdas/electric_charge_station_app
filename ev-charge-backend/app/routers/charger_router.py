from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.models.charger import ChargerCreate, Charger
from app.core.uow import AbstractUnitOfWork
from app.core.dependencies import get_uow

router = APIRouter()

@router.post("/", response_model=Charger, status_code=201)
def create_charger(charger: ChargerCreate, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        new_charger = Charger(**charger.model_dump(), id=0)
        uow.chargers.add(new_charger)
        uow.commit()
        return new_charger

@router.get("/", response_model=List[Charger])
def get_chargers(uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        return uow.chargers.list()

@router.get("/{charger_id}", response_model=Charger)
def get_charger(charger_id: int, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        charger = uow.chargers.get(charger_id)
        if not charger:
            raise HTTPException(status_code=404, detail="Charger not found")
        return charger
