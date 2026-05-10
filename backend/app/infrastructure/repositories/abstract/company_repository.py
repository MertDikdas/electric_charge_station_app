from abc import abstractmethod
from typing import Optional

from app.domain.models.company import CompanyEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository

class AbstractCompanyRepository(AbstractRepository[CompanyEntity]):
    @abstractmethod
    def get_by_name(self, name: str) -> Optional[CompanyEntity]:
        raise NotImplementedError

    @abstractmethod
    def get_all_active(self) -> list[CompanyEntity]:
        raise NotImplementedError