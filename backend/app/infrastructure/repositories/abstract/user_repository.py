from abc import abstractmethod
from typing import Optional

from app.infrastructure.database.tables import User
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractUserRepository(AbstractRepository[User]):
    @abstractmethod
    def get_by_email(self, email: str) -> Optional[User]:
        raise NotImplementedError
