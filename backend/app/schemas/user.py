from typing import Literal, Optional

from pydantic import BaseModel, Field, field_validator

UserRole = Literal["USER", "ADMIN"]

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
    company: Optional[Company] = None
    company_member: Optional[CompanyMember] = None

    class Config:
        from_attributes = True
