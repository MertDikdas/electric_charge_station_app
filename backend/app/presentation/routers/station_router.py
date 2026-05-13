from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query

from app.application.services.station_service import StationService
from app.core.dependencies import (
    AuthenticatedUser,
    get_station_service,
    get_station_manager,
    get_current_user,
    get_current_company_member,
    get_station_operator,
    get_admin,
    ensure_same_company,
    get_company_member,
    CompanyMember,
)
from app.domain.models.station import StationEntity
from app.schemas.charger import Charger
from app.schemas.station import (
    MonthlyRevenue,
    StationCreate,
    Station,
    StationStatusUpdate,
    StationUsageCount,
)
from app.domain.rules.station_rules import validate_station_entity
from typing import Dict, Any



router = APIRouter()


@router.post("/", response_model=Station, status_code=201)
def create_station(
    station: StationCreate,
    service: StationService = Depends(get_station_service),
    member: CompanyMember = Depends(get_current_company_member),
    current_user: AuthenticatedUser = Depends(get_station_manager),
):
    station_entity = StationEntity(**station.model_dump(),company_id=member.company_id)
    try:
        validate_station_entity(station_entity)
        return service.create_station(station_entity)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))



@router.get("/", response_model=List[Station])
def get_stations(service: StationService = Depends(get_station_service)):
    return service.get_all_stations()


@router.get("/nearby", response_model=List[Station])
def get_nearby_stations(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    km_radius: float = Query(5, gt=0),
    service: StationService = Depends(get_station_service),
):
    return service.get_nearby_stations(latitude, longitude, km_radius)

@router.get("/nearby/area", response_model=List[Station])
def get_nearby_stations_in_area(
    north_latitude: float = Query(..., ge=-90, le=90),
    south_latitude: float = Query(..., ge=-90, le=90),
    east_longitude: float = Query(..., ge=-180, le=180),
    west_longitude: float = Query(..., ge=-180, le=180),
    service: StationService = Depends(get_station_service),
):
    return service.get_nearby_stations_in_area(north_latitude, south_latitude, east_longitude, west_longitude)

@router.get("/search-compatible-in-area", response_model=List[Station])
def get_nearby_compatible_stations(
    north_latitude: float = Query(..., ge=-90, le=90),
    south_latitude: float = Query(..., ge=-90, le=90),
    east_longitude: float = Query(..., ge=-180, le=180),
    west_longitude: float = Query(..., ge=-180, le=180),
    vehicle_id: int = Query(..., gt=0),
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    try:
        return service.get_nearby_compatible_stations(
            north_latitude=north_latitude,
            south_latitude=south_latitude,
            east_longitude=east_longitude,
            west_longitude=west_longitude,
            vehicle_id=vehicle_id,
            current_user_id=current_user.id,
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))

@router.get("/by-company-id/{company_id}", response_model=List[Station])
def get_stations_by_company_id(
    company_id: int,
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    try:
        return service.get_stations_by_company_id(company_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/my/company", response_model=List[Station])
def get_my_company_stations(
    service: StationService = Depends(get_station_service),
    member: CompanyMember = Depends(get_current_company_member),
    current_user: AuthenticatedUser = Depends(get_company_member),
):
    try:
        return service.get_stations_by_company_id(member.company_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/my/company/monthly-revenue", response_model=MonthlyRevenue)
def get_my_company_monthly_revenue(
    year: int = Query(..., ge=2000),
    month: int = Query(..., ge=1, le=12),
    service: StationService = Depends(get_station_service),
    member: CompanyMember = Depends(get_current_company_member),
    current_user: AuthenticatedUser = Depends(get_company_member),
):
    try:
        revenue = service.get_company_monthly_revenue(member.company_id, year, month)
        return {"year": year, "month": month, "revenue": revenue}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/my/company/usage-counts", response_model=List[StationUsageCount])
def get_my_company_station_usage_counts(
    service: StationService = Depends(get_station_service),
    member: CompanyMember = Depends(get_current_company_member),
    current_user: AuthenticatedUser = Depends(get_company_member),
):
    try:
        return service.get_company_station_usage_counts(member.company_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/{station_id}/monthly-revenue", response_model=MonthlyRevenue)
def get_station_monthly_revenue(
    station_id: int,
    year: int = Query(..., ge=2000),
    month: int = Query(..., ge=1, le=12),
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_company_member),
    membership_check: AuthenticatedUser = Depends(ensure_same_company),
):
    try:
        revenue = service.get_station_monthly_revenue(station_id, year, month)
        return {"year": year, "month": month, "revenue": revenue}
    except ValueError as e:
        status_code = 404 if str(e) == "Station not found" else 400
        raise HTTPException(status_code=status_code, detail=str(e))

@router.get("/{station_id}/chargers", response_model=List[Charger])
def get_station_chargers(
    station_id: int,
    service: StationService = Depends(get_station_service),
):
    station = service.get_station(station_id)
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")

    return service.get_station_chargers(station_id)


@router.get("/{station_id}", response_model=Station)
def get_station(
    station_id: int,
    service: StationService = Depends(get_station_service),
):
    station = service.get_station(station_id)
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")
    return station


@router.put("/{station_id}", response_model=Station)
def update_station(
    station_id: int,
    station: StationCreate,
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    membership_check: AuthenticatedUser = Depends(ensure_same_company),    
):
    
    existing_station = service.get_station(station_id)
    if not existing_station:
        raise HTTPException(status_code=404, detail="Station not found")

    updated_station = StationEntity(id=station_id, **station.model_dump())
    try:
        validate_station_entity(updated_station)
        return service.update_station(updated_station)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/{station_id}/status", response_model=Station)
def update_station_status(
    station_id: int,
    status_update: StationStatusUpdate,
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    membership_check: AuthenticatedUser = Depends(ensure_same_company),
):
    try:
        station = service.update_station_status(station_id, status_update.status)
        if not station:
            raise HTTPException(status_code=404, detail="Station not found")
        return station
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{station_id}", status_code=204)
def delete_station(
    station_id: int,
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    membership_check: AuthenticatedUser = Depends(ensure_same_company),
):
    existing_station = service.get_station(station_id)
    if not existing_station:
        raise HTTPException(status_code=404, detail="Station not found")

    service.delete_station(station_id)

@router.delete("/admin/{station_id}", status_code=204)
def delete_station_admin(
    station_id: int,
    service: StationService = Depends(get_station_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    existing_station = service.get_station(station_id)
    if not existing_station:
        raise HTTPException(status_code=404, detail="Station not found")
    service.delete_station(station_id)
