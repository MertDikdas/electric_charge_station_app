from dataclasses import dataclass

from app.domain.models.base import BaseEntity


@dataclass
class CompanyMemberEntity(BaseEntity):
    company_id: int
    user_id: int
    role: str
    is_active: bool = True


CompanyMember = CompanyMemberEntity
