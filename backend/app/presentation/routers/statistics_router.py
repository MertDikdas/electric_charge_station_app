from datetime import date, datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.application.services.statistics_service import StatisticsService
from app.core.dependencies import (
    AuthenticatedUser,
    ensure_same_company,
    get_admin,
    get_company_member,
    get_current_company_member,
    get_statistics_service,
    get_station_manager,
)
from app.infrastructure.database.database import get_db
from app.infrastructure.database.tables import (
    ChargingSession,
    CompanyMember,
    Reservation,
    Station,
)
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

@router.get("/station-revenue/{station_id}")
def get_station_revenue(
    station_id: int,
    year: int = Query(default_factory=lambda: date.today().year, ge=2000),
    month: int | None = Query(default=None, ge=1, le=12),
    db: Session = Depends(get_db),
    _current_user: AuthenticatedUser = Depends(get_company_member),
    _membership_check: CompanyMember = Depends(ensure_same_company),
):
    query = (
        db.query(func.coalesce(func.sum(ChargingSession.cost), 0.0))
        .join(Reservation, Reservation.id == ChargingSession.reservation_id)
        .filter(
            Reservation.station_id == station_id,
            ChargingSession.status == "COMPLETED",
            func.extract("year", Reservation.date) == year,
        )
    )
    if month is not None:
        query = query.filter(func.extract("month", Reservation.date) == month)

    station = db.query(Station).filter(Station.id == station_id).first()
    if station is None:
        raise HTTPException(status_code=404, detail="Station not found")
    return {
        "station_id": station_id,
        "station_name": station.name,
        "year": year,
        "month": month,
        "revenue": float(query.scalar() or 0.0),
    }


@router.get("/company-revenue")
def get_company_revenue(
    year: int = Query(default_factory=lambda: date.today().year, ge=2000),
    month: int | None = Query(default=None, ge=1, le=12),
    db: Session = Depends(get_db),
    member: CompanyMember = Depends(get_current_company_member),
    _current_user: AuthenticatedUser = Depends(get_company_member),
):
    query = (
        db.query(func.coalesce(func.sum(ChargingSession.cost), 0.0))
        .join(Reservation, Reservation.id == ChargingSession.reservation_id)
        .join(Station, Station.id == Reservation.station_id)
        .filter(
            Station.company_id == member.company_id,
            ChargingSession.status == "COMPLETED",
            func.extract("year", Reservation.date) == year,
        )
    )
    if month is not None:
        query = query.filter(func.extract("month", Reservation.date) == month)

    monthly_rows = (
        db.query(
            func.extract("month", Reservation.date).label("month"),
            func.coalesce(func.sum(ChargingSession.cost), 0.0).label("revenue"),
            func.coalesce(func.sum(ChargingSession.consuming_power), 0.0).label("kwh"),
        )
        .join(Reservation, Reservation.id == ChargingSession.reservation_id)
        .join(Station, Station.id == Reservation.station_id)
        .filter(
            Station.company_id == member.company_id,
            ChargingSession.status == "COMPLETED",
            func.extract("year", Reservation.date) == year,
        )
        .group_by(func.extract("month", Reservation.date))
        .order_by(func.extract("month", Reservation.date))
        .all()
    )

    station_rows = (
        db.query(
            Station.id,
            Station.name,
            func.coalesce(func.sum(ChargingSession.cost), 0.0),
        )
        .outerjoin(Reservation, Reservation.station_id == Station.id)
        .outerjoin(ChargingSession, ChargingSession.reservation_id == Reservation.id)
        .filter(Station.company_id == member.company_id)
        .group_by(Station.id, Station.name)
        .order_by(func.coalesce(func.sum(ChargingSession.cost), 0.0).desc())
        .all()
    )

    return {
        "company_id": member.company_id,
        "year": year,
        "month": month,
        "revenue": float(query.scalar() or 0.0),
        "monthly": [
            {"month": int(row.month), "revenue": float(row.revenue or 0.0), "kwh": float(row.kwh or 0.0)}
            for row in monthly_rows
        ],
        "stations": [
            {"station_id": row[0], "station_name": row[1], "revenue": float(row[2] or 0.0)}
            for row in station_rows
        ],
    }


@router.get("/station-usage")
def get_station_usage(
    db: Session = Depends(get_db),
    member: CompanyMember = Depends(get_current_company_member),
    _current_user: AuthenticatedUser = Depends(get_company_member),
):
    rows = (
        db.query(
            Station.id,
            Station.name,
            func.count(Reservation.id),
            func.coalesce(func.sum(ChargingSession.consuming_power), 0.0),
        )
        .outerjoin(Reservation, Reservation.station_id == Station.id)
        .outerjoin(ChargingSession, ChargingSession.reservation_id == Reservation.id)
        .filter(Station.company_id == member.company_id)
        .group_by(Station.id, Station.name)
        .all()
    )
    return [
        {
            "station_id": station_id,
            "station_name": station_name,
            "usage_count": int(usage_count or 0),
            "energy_delivered": float(energy_delivered or 0.0),
        }
        for station_id, station_name, usage_count, energy_delivered in rows
    ]
