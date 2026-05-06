from typing import List, Optional

from fastapi import APIRouter, Body, Depends, HTTPException

from app.application.services.charger_session_service import ChargingSessionService
from app.core.dependencies import (
    AuthenticatedUser,
    get_admin_or_station_manager,
    get_charging_session_service,
    get_current_user,
)
from app.schemas.charging_session import (
    ChargingSession,
    ChargingSessionFinishRequest,
    ChargingSessionStartRequest,
)

router = APIRouter()


@router.post("/start", response_model=ChargingSession, status_code=201)
def start_session(
    request: ChargingSessionStartRequest,
    service: ChargingSessionService = Depends(get_charging_session_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    try:
        return service.start_session(
            request.reservation_id,
            current_user.id,
            current_user.is_staff,
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.patch("/{session_id}/finish", response_model=ChargingSession)
def finish_session(
    session_id: int,
    request: Optional[ChargingSessionFinishRequest] = Body(default=None),
    service: ChargingSessionService = Depends(get_charging_session_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    try:
        return service.finish_session(
            session_id,
            current_user.id,
            current_user.is_staff,
            request.end_time if request else None,
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("", response_model=List[ChargingSession])
def get_sessions(
    service: ChargingSessionService = Depends(get_charging_session_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    return service.get_all_sessions()


@router.get("/{session_id}", response_model=ChargingSession)
def get_session(
    session_id: int,
    service: ChargingSessionService = Depends(get_charging_session_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    session = service.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Charging session not found")

    if not service.can_access_session(session, current_user.id, current_user.is_staff):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return session
