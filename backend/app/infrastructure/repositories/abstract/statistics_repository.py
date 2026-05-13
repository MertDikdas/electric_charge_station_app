from abc import ABC, abstractmethod
from typing import List

from app.schemas.statistics import (
    AdminOverviewStatistics,
    CompanyRevenue,
    ManagerOverviewStatistics,
    StationOverviewStatistics,
    StationRevenue,
    StationUsage,
    StatusCount,
)


class AbstractStatisticsRepository(ABC):

    @abstractmethod
    def get_admin_overview(self, year: int, month: int) -> AdminOverviewStatistics:
        raise NotImplementedError

    @abstractmethod
    def get_manager_overview(
        self,
        company_id: int,
        year: int,
        month: int,
    ) -> ManagerOverviewStatistics:
        raise NotImplementedError

    @abstractmethod
    def get_admin_monthly_revenue(self, year: int, month: int) -> float:
        raise NotImplementedError

    @abstractmethod
    def get_company_monthly_revenue(
        self,
        company_id: int,
        year: int,
        month: int,
    ) -> float:
        raise NotImplementedError

    @abstractmethod
    def get_station_monthly_revenue(
        self,
        station_id: int,
        year: int,
        month: int,
    ) -> float:
        raise NotImplementedError

    @abstractmethod
    def get_station_overview(
        self,
        station_id: int,
        year: int,
        month: int,
    ) -> StationOverviewStatistics:
        raise NotImplementedError

    @abstractmethod
    def get_revenue_by_company(
        self,
        year: int,
        month: int,
        limit: int = 10,
    ) -> List[CompanyRevenue]:
        raise NotImplementedError

    @abstractmethod
    def get_revenue_by_station(
        self,
        year: int,
        month: int,
        company_id: int | None = None,
        limit: int = 10,
    ) -> List[StationRevenue]:
        raise NotImplementedError

    @abstractmethod
    def get_station_usage_counts(
        self,
        year: int,
        month: int,
        company_id: int | None = None,
        limit: int = 10,
    ) -> List[StationUsage]:
        raise NotImplementedError

    @abstractmethod
    def get_charger_status_counts(
        self,
        company_id: int | None = None,
    ) -> List[StatusCount]:
        raise NotImplementedError

    @abstractmethod
    def get_reservation_status_counts(
        self,
        company_id: int | None = None,
    ) -> List[StatusCount]:
        raise NotImplementedError
