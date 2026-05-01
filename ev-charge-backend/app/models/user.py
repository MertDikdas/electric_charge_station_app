from pydantic import BaseModel, Field

class UserCreate(BaseModel):
    name: str
    surname: str
    mail: str
    balance: float = 0.0

class User(UserCreate):
    id: int
