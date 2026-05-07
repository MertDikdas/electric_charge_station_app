from typing import Optional

from app.domain.models.user import UserEntity
from app.infrastructure.database.tables import User as UserModel
from app.infrastructure.repositories.abstract.user_repository import AbstractUserRepository
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyUserRepository(SqlAlchemyRepository[UserEntity, UserModel], AbstractUserRepository):
    model = UserModel

    def to_model(self, entity: UserEntity) -> UserModel:
        return UserModel(
            id=entity.id,
            name=entity.name,
            surname=entity.surname,
            email=entity.email,
            password_hash=entity.password_hash,
            balance=entity.balance,
            role=entity.role,
        )

    def to_entity(self, model: UserModel) -> UserEntity:
        return UserEntity(
            id=model.id,
            name=model.name,
            surname=model.surname,
            email=model.email,
            balance=model.balance,
            password_hash=model.password_hash,
            role=model.role,
        )

    def get_by_email(self, email: str) -> Optional[UserEntity]:
        model = self.session.query(UserModel).filter(UserModel.email == email).first()
        if model is None:
            return None
        return self.to_entity(model)
