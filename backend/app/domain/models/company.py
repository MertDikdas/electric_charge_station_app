from dataclasses import dataclass
from app.domain.models.base import BaseEntity
from typing import Optional

@dataclass
class CompanyEntity(BaseEntity):
    name: str
    tax_number: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    is_active: bool = True

Company = CompanyEntity