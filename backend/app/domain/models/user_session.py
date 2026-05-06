from dataclasses import dataclass
from datetime import datetime

from app.domain.models.base import BaseEntity


@dataclass
class UserSessionEntity(BaseEntity):
    user_id: int
    token: str
    created_at: datetime
    expires_at: datetime
    is_revoked: bool = False


UserSession = UserSessionEntity
