from typing import Optional, List

from app.domain.models.company import CompanyEntity
from app.core.uow import AbstractUnitOfWork


class CompanyService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_company(self, company: CompanyEntity) -> CompanyEntity:
        with self.uow:
            existing_company = self.uow.companies.get_by_name(company.name)
            if existing_company:
                raise ValueError("Company with this name already exists")   
            new_company = self.uow.companies.add(company)
            self.uow.commit()
            return new_company
        
    def get_company(self, company_id: int) -> Optional[CompanyEntity]:
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            return self.uow.companies.get(company_id)
        
    def get_all_companies(self) -> List[CompanyEntity]:
        with self.uow:
            return self.uow.companies.list()
        
    def get_all_active_companies(self) -> List[CompanyEntity]:
        with self.uow:
            return self.uow.companies.get_all_active()
    
    def update_company(self, company_id: int, updated_company: dict) -> CompanyEntity:
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            for field, value in updated_company.items():
                setattr(company, field, value)
            self.uow.companies.update(company)
            self.uow.commit()
            return company
        
    def delete_company(self, company_id: int) -> None:
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            self.uow.companies.delete(company)
            self.uow.commit()
    
    def deactivate_company(self, company_id: int) -> CompanyEntity:
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            company.is_active = False
            updated_company = self.uow.companies.update(company)
            self.uow.commit()
            return updated_company
        
    def activate_company(self, company_id: int) -> CompanyEntity:
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            company.is_active = True
            updated_company = self.uow.companies.update(company)
            self.uow.commit()
            return updated_company
