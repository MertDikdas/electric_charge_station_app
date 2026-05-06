from dataclasses import dataclass

from app.domain.models.user import UserEntity


@dataclass
class AuthResponseEntity:
    access_token: str
    user: UserEntity
    token_type: str = "bearer"


AuthResponse = AuthResponseEntity
