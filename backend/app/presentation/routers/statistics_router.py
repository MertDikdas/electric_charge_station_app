from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query

from app.application.services.statistics_service import StatisticsService
from app.core.dependencies import (
    AuthenticatedUser,
    get_admin,
    get_current_company_member,
    get_statistics_service,
    get_station_manager,
)
from app.infrastructure.database.tables import CompanyMember
from app.schemas.statistics import (
    AdminOverviewStatistics,
    CompanyRevenue,
    ManagerOverviewStatistics,
    StationOverviewStatistics,
    StationRevenue,
    StationUsage,
    StatusCount,
)

router = APIRouter()


def _default_year() -> int:
    return datetime.now().year


def _default_month() -> int:
    return datetime.now().month


@router.get("/admin/overview", response_model=AdminOverviewStatistics)
def get_admin_overview(
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_admin_overview(year, month)


@router.get("/admin/monthly-revenue")
def get_admin_monthly_revenue(
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_admin_monthly_revenue(year, month)


@router.get("/admin/companies/revenue", response_model=List[CompanyRevenue])
def get_revenue_by_company(
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    limit: int = Query(default=10, ge=1, le=50),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_revenue_by_company(year, month, limit)


@router.get("/admin/stations/revenue", response_model=List[StationRevenue])
def get_admin_revenue_by_station(
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    limit: int = Query(default=10, ge=1, le=50),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_revenue_by_station(year, month, None, limit)


@router.get("/admin/stations/usage", response_model=List[StationUsage])
def get_admin_station_usage(
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    limit: int = Query(default=10, ge=1, le=50),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_station_usage_counts(year, month, None, limit)


@router.get(
    "/admin/stations/{station_id}/overview",
    response_model=StationOverviewStatistics,
)
def get_admin_station_overview(
    station_id: int,
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    try:
        return service.get_station_overview(station_id, year, month)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/admin/chargers/status", response_model=List[StatusCount])
def get_admin_charger_status_counts(
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_charger_status_counts()


@router.get("/admin/reservations/status", response_model=List[StatusCount])
def get_admin_reservation_status_counts(
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_reservation_status_counts()


@router.get("/manager/overview", response_model=ManagerOverviewStatistics)
def get_manager_overview(
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    member: CompanyMember = Depends(get_current_company_member),
):
    try:
        return service.get_manager_overview(member.company_id, year, month)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/manager/monthly-revenue")
def get_manager_monthly_revenue(
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    member: CompanyMember = Depends(get_current_company_member),
):
    return service.get_company_monthly_revenue(member.company_id, year, month)


@router.get("/manager/stations/revenue", response_model=List[StationRevenue])
def get_manager_revenue_by_station(
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    limit: int = Query(default=10, ge=1, le=50),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    member: CompanyMember = Depends(get_current_company_member),
):
    return service.get_revenue_by_station(year, month, member.company_id, limit)


@router.get("/manager/stations/usage", response_model=List[StationUsage])
def get_manager_station_usage(
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    limit: int = Query(default=10, ge=1, le=50),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    member: CompanyMember = Depends(get_current_company_member),
):
    return service.get_station_usage_counts(year, month, member.company_id, limit)


@router.get(
    "/manager/stations/{station_id}/overview",
    response_model=StationOverviewStatistics,
)
def get_manager_station_overview(
    station_id: int,
    year: int = Query(default_factory=_default_year),
    month: int = Query(default_factory=_default_month, ge=1, le=12),
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    member: CompanyMember = Depends(get_current_company_member),
):
    try:
        return service.get_manager_station_overview(
            station_id,
            member.company_id,
            year,
            month,
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc


@router.get("/manager/chargers/status", response_model=List[StatusCount])
def get_manager_charger_status_counts(
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    member: CompanyMember = Depends(get_current_company_member),
):
    return service.get_charger_status_counts(member.company_id)


@router.get("/manager/reservations/status", response_model=List[StatusCount])
def get_manager_reservation_status_counts(
    service: StatisticsService = Depends(get_statistics_service),
    current_user: AuthenticatedUser = Depends(get_station_manager),
    member: CompanyMember = Depends(get_current_company_member),
):
    return service.get_reservation_status_counts(member.company_id)
