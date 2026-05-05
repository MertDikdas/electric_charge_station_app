from pydantic import BaseModel, Field

class UserBase(BaseModel):
    name: str
    surname: str
    email: str
    balance: float = 0.0


class UserCreate(UserBase):
    password: str = Field(..., min_length=6, max_length=72)

class User(UserBase):
    id: int
    
    class Config:
        from_attributes = True