from abc import abstractmethod
from typing import Optional

from app.domain.models.company_member import CompanyMemberEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository

class AbstractCompanyMemberRepository(AbstractRepository[CompanyMemberEntity]):
    @abstractmethod
    def get_by_company_and_user(self, company_id: int, user_id: int) -> Optional[CompanyMemberEntity]:
        raise NotImplementedError
    
    @abstractmethod
    def get_all_active_by_company(self, company_id: int) -> list[CompanyMemberEntity]:
        raise NotImplementedError

    @abstractmethod
    def get_all_by_company(self, company_id: int) -> list[CompanyMemberEntity]:
        raise NotImplementedError
    
    @abstractmethod
    def get_all_active(self) -> list[CompanyMemberEntity]:
        raise NotImplementedError
    
    @abstractmethod
    def deactivate_by_user_id(self, user_id: int) -> None:
        raise NotImplementedError
    
    @abstractmethod
    def deactivate_by_company_id(self, company_id: int) -> None:
        raise NotImplementedError
