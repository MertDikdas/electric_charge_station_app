from typing import List

from fastapi import APIRouter, Depends

from app.application.services.charger_session_service import ChargingSessionService
from app.core.dependencies import get_charging_session_service
from app.domain.models.charging_session import ChargingSessionCreate, ChargingSession

router = APIRouter()


@router.post("/", response_model=ChargingSession, status_code=201)
def create_session(
    session: ChargingSessionCreate,
    service: ChargingSessionService = Depends(get_charging_session_service),
):
    return service.create_session(session)


@router.get("/", response_model=List[ChargingSession])
def get_sessions(
    service: ChargingSessionService = Depends(get_charging_session_service),
):
    return service.get_all_sessions()
