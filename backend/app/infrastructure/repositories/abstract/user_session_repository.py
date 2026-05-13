from typing import Optional

from app.domain.models.user_session import UserSessionEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractUserSessionRepository(AbstractRepository[UserSessionEntity]):
    def get_by_token(self, token: str) -> Optional[UserSessionEntity]:
        raise NotImplementedError

    def revoke_token(self, token: str) -> bool:
        raise NotImplementedError

    def revoke_all_for_user(self, user_id: int) -> int:
        raise NotImplementedError
