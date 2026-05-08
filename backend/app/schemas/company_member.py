from typing import Literal, Optional

from pydantic import BaseModel


CompanyMemberRole = Literal["STATION_MANAGER", "STATION_OPERATOR"]


class CompanyMemberCreate(BaseModel):
    user_id: int
    role: CompanyMemberRole


class CompanyMemberUpdate(BaseModel):
    role: Optional[CompanyMemberRole] = None
    is_active: Optional[bool] = None


class CompanyMember(BaseModel):
    id: int
    company_id: int
    user_id: int
    role: CompanyMemberRole
    is_active: bool

    class Config:
        from_attributes = True
