from pydantic import BaseModel, Field

class UserCreate(BaseModel):
    name: str
    surname: str
    mail: str
    balance: float = 0.0
    password: str = Field(..., min_length=2)

class User(UserCreate):
    id: int
