from datetime import datetime

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.infrastructure.database.tables import (
    Charger,
    ChargingSession,
    Company,
    Payment,
    Reservation,
    Station,
    User,
)
from app.infrastructure.repositories.abstract.statistics_repository import (
    AbstractStatisticsRepository,
)
from app.schemas.statistics import (
    AdminOverviewStatistics,
    CompanyRevenue,
    ManagerOverviewStatistics,
    StationRevenue,
    StationUsage,
    StatusCount,
)


class SqlAlchemyStatisticsRepository(AbstractStatisticsRepository):
    def __init__(self, session: Session):
        self.session = session

    def _month_range(self, year: int, month: int) -> tuple[datetime, datetime]:
        start_date = datetime(year, month, 1)

        if month == 12:
            end_date = datetime(year + 1, 1, 1)
        else:
            end_date = datetime(year, month + 1, 1)

        return start_date, end_date

    def _completed_payment_filter(self, year: int, month: int):
        start_date, end_date = self._month_range(year, month)

        return (
            Payment.status == "COMPLETED",
            Payment.payment_date >= start_date,
            Payment.payment_date < end_date,
        )

    def get_admin_overview(self, year: int, month: int) -> AdminOverviewStatistics:
        monthly_revenue = self.get_admin_monthly_revenue(year, month)

        total_users = self.session.query(func.count(User.id)).scalar() or 0
        total_companies = self.session.query(func.count(Company.id)).scalar() or 0
        active_companies = (
            self.session.query(func.count(Company.id))
            .filter(Company.is_active == True)
            .scalar()
            or 0
        )

        total_stations = self.session.query(func.count(Station.id)).scalar() or 0
        available_stations = (
            self.session.query(func.count(Station.id))
            .filter(Station.status == "AVAILABLE")
            .scalar()
            or 0
        )

        total_chargers = self.session.query(func.count(Charger.id)).scalar() or 0
        available_chargers = (
            self.session.query(func.count(Charger.id))
            .filter(Charger.status == "AVAILABLE")
            .scalar()
            or 0
        )

        active_sessions = (
            self.session.query(func.count(ChargingSession.reservation_id))
            .filter(ChargingSession.status.in_(("STARTED", "IN_PROGRESS")))
            .scalar()
            or 0
        )

        total_reservations = self.session.query(func.count(Reservation.id)).scalar() or 0

        completed_payments = (
            self.session.query(func.count(Payment.id))
            .filter(Payment.status == "COMPLETED")
            .scalar()
            or 0
        )

        total_energy_consumed = (
            self.session.query(func.coalesce(func.sum(ChargingSession.consuming_power), 0))
            .filter(ChargingSession.status == "COMPLETED")
            .scalar()
            or 0
        )

        return AdminOverviewStatistics(
            total_users=int(total_users),
            total_companies=int(total_companies),
            active_companies=int(active_companies),
            total_stations=int(total_stations),
            available_stations=int(available_stations),
            total_chargers=int(total_chargers),
            available_chargers=int(available_chargers),
            active_sessions=int(active_sessions),
            total_reservations=int(total_reservations),
            completed_payments=int(completed_payments),
            monthly_revenue=float(monthly_revenue),
            total_energy_consumed=float(total_energy_consumed),
        )

    def get_manager_overview(
        self,
        company_id: int,
        year: int,
        month: int,
    ) -> ManagerOverviewStatistics:
        company = self.session.query(Company).filter(Company.id == company_id).first()
        if company is None:
            raise LookupError("Company not found")

        monthly_revenue = self.get_company_monthly_revenue(company_id, year, month)

        total_stations = (
            self.session.query(func.count(Station.id))
            .filter(Station.company_id == company_id)
            .scalar()
            or 0
        )

        available_stations = (
            self.session.query(func.count(Station.id))
            .filter(
                Station.company_id == company_id,
                Station.status == "AVAILABLE",
            )
            .scalar()
            or 0
        )

        total_chargers = (
            self.session.query(func.count(Charger.id))
            .join(Station, Charger.station_id == Station.id)
            .filter(Station.company_id == company_id)
            .scalar()
            or 0
        )

        available_chargers = (
            self.session.query(func.count(Charger.id))
            .join(Station, Charger.station_id == Station.id)
            .filter(
                Station.company_id == company_id,
                Charger.status == "AVAILABLE",
            )
            .scalar()
            or 0
        )

        active_sessions = (
            self.session.query(func.count(ChargingSession.reservation_id))
            .join(Reservation, ChargingSession.reservation_id == Reservation.id)
            .join(Charger, Reservation.charger_id == Charger.id)
            .join(Station, Charger.station_id == Station.id)
            .filter(
                Station.company_id == company_id,
                ChargingSession.status.in_(("STARTED", "IN_PROGRESS")),
            )
            .scalar()
            or 0
        )

        total_reservations = (
            self.session.query(func.count(Reservation.id))
            .join(Charger, Reservation.charger_id == Charger.id)
            .join(Station, Charger.station_id == Station.id)
            .filter(Station.company_id == company_id)
            .scalar()
            or 0
        )

        completed_payments = (
            self.session.query(func.count(Payment.id))
            .join(Reservation, Payment.reservation_id == Reservation.id)
            .join(Charger, Reservation.charger_id == Charger.id)
            .join(Station, Charger.station_id == Station.id)
            .filter(
                Station.company_id == company_id,
                Payment.status == "COMPLETED",
            )
            .scalar()
            or 0
        )

        total_energy_consumed = (
            self.session.query(func.coalesce(func.sum(ChargingSession.consuming_power), 0))
            .join(Reservation, ChargingSession.reservation_id == Reservation.id)
            .join(Charger, Reservation.charger_id == Charger.id)
            .join(Station, Charger.station_id == Station.id)
            .filter(
                Station.company_id == company_id,
                ChargingSession.status == "COMPLETED",
            )
            .scalar()
            or 0
        )

        return ManagerOverviewStatistics(
            company_id=company.id,
            company_name=company.name,
            total_stations=int(total_stations),
            available_stations=int(available_stations),
            total_chargers=int(total_chargers),
            available_chargers=int(available_chargers),
            active_sessions=int(active_sessions),
            total_reservations=int(total_reservations),
            completed_payments=int(completed_payments),
            monthly_revenue=float(monthly_revenue),
            total_energy_consumed=float(total_energy_consumed),
        )

    def get_admin_monthly_revenue(self, year: int, month: int) -> float:
        total = (
            self.session.query(func.coalesce(func.sum(Payment.amount), 0))
            .filter(*self._completed_payment_filter(year, month))
            .scalar()
            or 0
        )
        return float(total)

    def get_company_monthly_revenue(
        self,
        company_id: int,
        year: int,
        month: int,
    ) -> float:
        total = (
            self.session.query(func.coalesce(func.sum(Payment.amount), 0))
            .join(Reservation, Payment.reservation_id == Reservation.id)
            .join(Charger, Reservation.charger_id == Charger.id)
            .join(Station, Charger.station_id == Station.id)
            .filter(
                Station.company_id == company_id,
                *self._completed_payment_filter(year, month),
            )
            .scalar()
            or 0
        )
        return float(total)

    def get_station_monthly_revenue(
        self,
        station_id: int,
        year: int,
        month: int,
    ) -> float:
        total = (
            self.session.query(func.coalesce(func.sum(Payment.amount), 0))
            .join(Reservation, Payment.reservation_id == Reservation.id)
            .join(Charger, Reservation.charger_id == Charger.id)
            .filter(
                Charger.station_id == station_id,
                *self._completed_payment_filter(year, month),
            )
            .scalar()
            or 0
        )
        return float(total)

    def get_revenue_by_company(
        self,
        year: int,
        month: int,
        limit: int = 10,
    ) -> list[CompanyRevenue]:
        rows = (
            self.session.query(
                Company.id.label("company_id"),
                Company.name.label("company_name"),
                func.coalesce(func.sum(Payment.amount), 0).label("revenue"),
            )
            .join(Station, Station.company_id == Company.id)
            .join(Charger, Charger.station_id == Station.id)
            .join(Reservation, Reservation.charger_id == Charger.id)
            .join(Payment, Payment.reservation_id == Reservation.id)
            .filter(*self._completed_payment_filter(year, month))
            .group_by(Company.id, Company.name)
            .order_by(func.coalesce(func.sum(Payment.amount), 0).desc())
            .limit(limit)
            .all()
        )

        return [
            CompanyRevenue(
                company_id=row.company_id,
                company_name=row.company_name,
                revenue=float(row.revenue or 0),
            )
            for row in rows
        ]

    def get_revenue_by_station(
        self,
        year: int,
        month: int,
        company_id: int | None = None,
        limit: int = 10,
    ) -> list[StationRevenue]:
        query = (
            self.session.query(
                Station.id.label("station_id"),
                Station.address.label("station_address"),
                func.coalesce(func.sum(Payment.amount), 0).label("revenue"),
            )
            .join(Charger, Charger.station_id == Station.id)
            .join(Reservation, Reservation.charger_id == Charger.id)
            .join(Payment, Payment.reservation_id == Reservation.id)
            .filter(*self._completed_payment_filter(year, month))
        )

        if company_id is not None:
            query = query.filter(Station.company_id == company_id)

        rows = (
            query
            .group_by(Station.id, Station.address)
            .order_by(func.coalesce(func.sum(Payment.amount), 0).desc())
            .limit(limit)
            .all()
        )

        return [
            StationRevenue(
                station_id=row.station_id,
                station_address=row.station_address,
                revenue=float(row.revenue or 0),
            )
            for row in rows
        ]

    def get_station_usage_counts(
        self,
        year: int,
        month: int,
        company_id: int | None = None,
        limit: int = 10,
    ) -> list[StationUsage]:
        start_date, end_date = self._month_range(year, month)

        query = (
            self.session.query(
                Station.id.label("station_id"),
                Station.address.label("station_address"),
                func.count(ChargingSession.reservation_id).label("usage_count"),
            )
            .join(Charger, Charger.station_id == Station.id)
            .join(Reservation, Reservation.charger_id == Charger.id)
            .join(ChargingSession, ChargingSession.reservation_id == Reservation.id)
            .filter(
                Reservation.date >= start_date.date(),
                Reservation.date < end_date.date(),
                ChargingSession.status.in_(("STARTED", "IN_PROGRESS", "COMPLETED")),
            )
        )

        if company_id is not None:
            query = query.filter(Station.company_id == company_id)

        rows = (
            query
            .group_by(Station.id, Station.address)
            .order_by(func.count(ChargingSession.reservation_id).desc())
            .limit(limit)
            .all()
        )

        return [
            StationUsage(
                station_id=row.station_id,
                station_address=row.station_address,
                usage_count=int(row.usage_count or 0),
            )
            for row in rows
        ]

    def get_charger_status_counts(
        self,
        company_id: int | None = None,
    ) -> list[StatusCount]:
        query = (
            self.session.query(
                Charger.status.label("status"),
                func.count(Charger.id).label("count"),
            )
        )

        if company_id is not None:
            query = (
                query
                .join(Station, Charger.station_id == Station.id)
                .filter(Station.company_id == company_id)
            )

        rows = (
            query
            .group_by(Charger.status)
            .order_by(Charger.status)
            .all()
        )

        return [
            StatusCount(status=row.status, count=int(row.count or 0))
            for row in rows
        ]

    def get_reservation_status_counts(
        self,
        company_id: int | None = None,
    ) -> list[StatusCount]:
        query = (
            self.session.query(
                Reservation.status.label("status"),
                func.count(Reservation.id).label("count"),
            )
        )

        if company_id is not None:
            query = (
                query
                .join(Charger, Reservation.charger_id == Charger.id)
                .join(Station, Charger.station_id == Station.id)
                .filter(Station.company_id == company_id)
            )

        rows = (
            query
            .group_by(Reservation.status)
            .order_by(Reservation.status)
            .all()
        )

        return [
            StatusCount(status=row.status, count=int(row.count or 0))
            for row in rows
        ]