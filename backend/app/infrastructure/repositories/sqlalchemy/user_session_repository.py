from typing import Optional

from app.domain.models.user_session import UserSessionEntity
from app.infrastructure.database.tables import UserSession as UserSessionModel
from app.infrastructure.repositories.abstract.user_session_repository import (
    AbstractUserSessionRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyUserSessionRepository(
    SqlAlchemyRepository[UserSessionEntity, UserSessionModel],
    AbstractUserSessionRepository,
):
    model = UserSessionModel

    def to_model(self, entity: UserSessionEntity) -> UserSessionModel:
        return UserSessionModel(
            id=entity.id,
            user_id=entity.user_id,
            token=entity.token,
            is_revoked=entity.is_revoked,
            created_at=entity.created_at,
            expires_at=entity.expires_at,
        )

    def to_entity(self, model: UserSessionModel) -> UserSessionEntity:
        return UserSessionEntity(
            id=model.id,
            user_id=model.user_id,
            token=model.token,
            is_revoked=model.is_revoked,
            created_at=model.created_at,
            expires_at=model.expires_at,
        )

    def get_by_token(self, token: str) -> Optional[UserSessionEntity]:
        model = self.session.query(self.model).filter(self.model.token == token).first()
        if model is None:
            return None
        return self.to_entity(model)

    def revoke_token(self, token: str) -> bool:
        model = self.session.query(self.model).filter(self.model.token == token).first()
        if model is None:
            return False

        model.is_revoked = True
        self.session.flush()
        return True
