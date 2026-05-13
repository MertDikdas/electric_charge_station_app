from pydantic import BaseModel


class StatusCount(BaseModel):
    status: str
    count: int


class StationRevenue(BaseModel):
    station_id: int
    station_address: str
    revenue: float


class CompanyRevenue(BaseModel):
    company_id: int
    company_name: str
    revenue: float


class StationUsage(BaseModel):
    station_id: int
    station_address: str
    usage_count: int


class AdminOverviewStatistics(BaseModel):
    total_users: int
    total_companies: int
    active_companies: int
    total_stations: int
    available_stations: int
    total_chargers: int
    available_chargers: int
    active_sessions: int
    total_reservations: int
    completed_payments: int
    monthly_revenue: float
    total_energy_consumed: float


class ManagerOverviewStatistics(BaseModel):
    company_id: int
    company_name: str
    total_stations: int
    available_stations: int
    total_chargers: int
    available_chargers: int
    active_sessions: int
    total_reservations: int
    completed_payments: int
    monthly_revenue: float
    total_energy_consumed: float