from typing import Literal, Optional

from pydantic import BaseModel, Field, field_validator

UserRole = Literal["USER", "COMPANY_MANAGER", "COMPANY_OPERATOR", "ADMIN", "STATION_MANAGER", "STATION_OPERATOR"]

class UserBase(BaseModel):
    name: str
    surname: str
    email: str
    balance: float = 0.0

    @field_validator("name", "surname", "email")
    @classmethod
    def strip_text_fields(cls, value: str) -> str:
        return value.strip()


class UserCreate(BaseModel):
    name: str
    surname: str
    email: str
    balance: float = 0.0
    password: str = Field(..., min_length=6, max_length=72)

    @field_validator("name", "surname", "email")
    @classmethod
    def strip_text_fields(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Field cannot be empty")
        return value

class User(UserBase):
    id: int
    role: UserRole = "USER"
    company_id: Optional[int] = None
    membership_role: Optional[str] = None
    
    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: str
    password: str

    @field_validator("email")
    @classmethod
    def strip_email(cls, value: str) -> str:
        return value.strip()

class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: User

    class Config:
        from_attributes = True
