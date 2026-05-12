from typing import Literal

from pydantic import BaseModel, Field

UserRole = Literal["USER", "ADMIN"]

class UserBase(BaseModel):
    name: str
    surname: str
    email: str
    balance: float = 0.0


class UserCreate(BaseModel):
    name: str
    surname: str
    email: str
    balance: float = 0.0
    password: str = Field(..., min_length=6, max_length=72)

class User(UserBase):
    id: int
    role: UserRole = "USER"
    
    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: str
    password: str

class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: User

    class Config:
        from_attributes = True
