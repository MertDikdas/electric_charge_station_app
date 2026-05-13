from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.dependencies import (
    AuthenticatedUser,
    ensure_same_company,
    get_company_member,
    get_current_company_member,
)
from app.infrastructure.database.database import get_db
from app.infrastructure.database.tables import (
    Charger,
    ChargingSession,
    CompanyMember,
    Reservation,
    Station,
)

router = APIRouter()


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

    return {"station_id": station_id, "year": year, "month": month, "revenue": float(query.scalar() or 0.0)}


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
