from pydantic import BaseModel, field_validator
from typing import Optional

class CompanyCreate(BaseModel):
    name: str
    tax_number: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    is_active: bool = True

    @field_validator("name")
    @classmethod
    def name_must_not_be_empty(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Company name must not be empty")
        return value
    
class CompanyUpdate(BaseModel):
    name: Optional[str] = None
    tax_number: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    is_active: Optional[bool] = None

class CompanyActivate(BaseModel):
    is_active: bool

class Company(BaseModel):
    id: int
    name: str
    tax_number: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    is_active: bool

    class Config:
        from_attributes = True