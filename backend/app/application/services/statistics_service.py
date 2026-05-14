from app.core.uow import AbstractUnitOfWork
from app.infrastructure.database.tables import CompanyMember


class StatisticsService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def get_admin_overview(self, year: int, month: int):
        with self.uow:
            return self.uow.statistics.get_admin_overview(year, month)

    def get_manager_overview(self, company_id: int, year: int, month: int):
        with self.uow:
            return self.uow.statistics.get_manager_overview(company_id, year, month)

    def get_admin_monthly_revenue(self, year: int, month: int):
        with self.uow:
            return {"revenue": self.uow.statistics.get_admin_monthly_revenue(year, month)}

    def get_company_monthly_revenue(self, company_id: int, year: int, month: int):
        with self.uow:
            return {
                "company_id": company_id,
                "revenue": self.uow.statistics.get_company_monthly_revenue(
                    company_id,
                    year,
                    month,
                ),
            }

    def get_station_monthly_revenue(self, station_id: int, year: int, month: int):
        with self.uow:
            return {
                "station_id": station_id,
                "revenue": self.uow.statistics.get_station_monthly_revenue(
                    station_id,
                    year,
                    month,
                ),
            }

    def get_station_overview(self, station_id: int, year: int, month: int):
        with self.uow:
            return self.uow.statistics.get_station_overview(station_id, year, month)

    def get_manager_station_overview(
        self,
        station_id: int,
        company_id: int,
        year: int,
        month: int,
    ):
        with self.uow:
            station_overview = self.uow.statistics.get_station_overview(
                station_id,
                year,
                month,
            )
            if station_overview.company_id != company_id:
                raise PermissionError(
                    "You are not allowed to access this station statistics"
                )

            return station_overview

    def get_revenue_by_company(self, year: int, month: int, limit: int = 10):
        with self.uow:
            return self.uow.statistics.get_revenue_by_company(year, month, limit)

    def get_revenue_by_station(
        self,
        year: int,
        month: int,
        company_id: int | None = None,
        limit: int = 10,
    ):
        with self.uow:
            return self.uow.statistics.get_revenue_by_station(
                year,
                month,
                company_id,
                limit,
            )

    def get_station_usage_counts(
        self,
        year: int,
        month: int,
        company_id: int | None = None,
        limit: int = 10,
    ):
        with self.uow:
            return self.uow.statistics.get_station_usage_counts(
                year,
                month,
                company_id,
                limit,
            )

    def get_charger_status_counts(self, company_id: int | None = None):
        with self.uow:
            return self.uow.statistics.get_charger_status_counts(company_id)

    def get_reservation_status_counts(self, company_id: int | None = None):
        with self.uow:
            return self.uow.statistics.get_reservation_status_counts(company_id)
