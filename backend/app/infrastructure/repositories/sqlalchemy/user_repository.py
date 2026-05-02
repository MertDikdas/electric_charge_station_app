from typing import Optional

from app.infrastructure.database.tables import User
from app.infrastructure.repositories.abstract.user_repository import AbstractUserRepository
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyUserRepository(SqlAlchemyRepository[User], AbstractUserRepository):
    model = User

    def get_by_email(self, email: str) -> Optional[User]:
        return self.session.query(User).filter(User.email == email).first()
