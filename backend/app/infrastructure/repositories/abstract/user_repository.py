from abc import abstractmethod
from typing import List
from typing import Optional

from app.domain.models.user import UserEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractUserRepository(AbstractRepository[UserEntity]):
    @abstractmethod
    def get_by_email(self, email: str) -> Optional[UserEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_by_company_id(self, company_id: int) -> List[UserEntity]:
        raise NotImplementedError
