from typing import Literal, Optional

from pydantic import BaseModel


CompanyMemberRole = Literal["STATION_MANAGER", "STATION_OPERATOR"]


class CompanyMemberCreate(BaseModel):
    company_id: int
    user_id: int
    role: CompanyMemberRole
    is_active: bool = True


class CompanyMemberUpdate(BaseModel):
    company_id: Optional[int] = None
    role: Optional[CompanyMemberRole] = None
    is_active: Optional[bool] = None

class CompanyMemberRoleUpdate(BaseModel):
    role: CompanyMemberRole

class CompanyMemberStatusUpdate(BaseModel):
    is_active: bool


class CompanyMemberUser(BaseModel):
    id: int
    name: str
    surname: str
    email: str
    is_active: bool
    balance: float = 0.0
    role: str = "USER"

    class Config:
        from_attributes = True


class CompanyMember(BaseModel):
    id: int
    company_id: int
    user_id: int
    role: CompanyMemberRole
    is_active: bool
    user: Optional[CompanyMemberUser] = None

    class Config:
        from_attributes = True
