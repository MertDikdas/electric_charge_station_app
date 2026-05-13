from dataclasses import dataclass
from typing import Optional

from app.domain.models.user import UserEntity
from app.domain.models.company import CompanyEntity
from app.domain.models.company_member import CompanyMemberEntity


@dataclass
class AuthResponseEntity:
    access_token: str
    user: UserEntity
    token_type: str = "bearer"
    company: Optional[CompanyEntity] = None
    company_member: Optional[CompanyMemberEntity] = None


AuthResponse = AuthResponseEntity