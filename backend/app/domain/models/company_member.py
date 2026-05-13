from dataclasses import dataclass
from typing import Optional

from app.domain.models.base import BaseEntity
from app.domain.models.user import UserEntity


@dataclass
class CompanyMemberEntity(BaseEntity):
    company_id: int
    user_id: int
    role: str
    is_active: bool = True
    user: Optional[UserEntity] = None


CompanyMember = CompanyMemberEntity
