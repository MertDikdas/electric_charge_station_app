from pydantic import BaseModel, Field

class UserBase(BaseModel):
    name: str
    surname: str
    mail: str
    balance: float = 0.0


class UserCreate(UserBase):
    password: str = Field(..., min_length=2)

class User(UserCreate):
    id: int
    
    class Config:
        from_attributes = True