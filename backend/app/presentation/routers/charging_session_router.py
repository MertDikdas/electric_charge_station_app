from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.domain.models.charging_session import ChargingSessionCreate, ChargingSession
from app.core.uow import AbstractUnitOfWork
from app.core.dependencies import get_uow

router = APIRouter()

@router.post("/", response_model=ChargingSession, status_code=201)
def create_session(session: ChargingSessionCreate, uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        # Pydantic'te id kullanmadık (Weak entity) ama isterseniz bir session_id uretilebilir
        # Biz InMemoryRepository kullandigimiz icin repoya ekleyince otomatik id atanacak, 
        # ancak modelde id olmadigi icin problem cikmaz. 
        # Modeli bir sozluk olarak ya da oldugu gibi ekleyebiliriz.
        new_session = ChargingSession(**session.model_dump())
        uow.charging_sessions.add(new_session)
        uow.commit()
        return new_session

@router.get("/", response_model=List[ChargingSession])
def get_sessions(uow: AbstractUnitOfWork = Depends(get_uow)):
    with uow:
        return uow.charging_sessions.list()
