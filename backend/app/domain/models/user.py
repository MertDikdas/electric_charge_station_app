from dataclasses import dataclass

from app.domain.models.base import BaseEntity


@dataclass
class UserEntity(BaseEntity):
    name: str
    surname: str
    email: str
    balance: float = 0.0
    password_hash: str = ""


User = UserEntity
