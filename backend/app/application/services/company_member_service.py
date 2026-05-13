from app.domain.models.company_member import CompanyMemberEntity
from app.domain.rules.company_member_rules import (
    validate_company_member_entity,
    validate_company_member_role,
    validate_company_member_status,
)
from app.core.uow import AbstractUnitOfWork


class CompanyMemberService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def add_member(self, company_member: CompanyMemberEntity) -> CompanyMemberEntity:
        validate_company_member_entity(company_member)

        with self.uow:
            company = self.uow.companies.get(company_member.company_id)
            if not company:
                raise ValueError("Company not found")
            if not company.is_active and company_member.is_active:
                raise ValueError("Cannot add active member to inactive company")
            user = self.uow.users.get(company_member.user_id)
            if not user:
                raise ValueError("User not found")  
            member = self.uow.company_members.get_by_company_and_user(company_member.company_id, company_member.user_id)
            if member:
                raise ValueError("User is already a member of this company")
            new_member = self.uow.company_members.add(company_member)
            self.uow.commit()
            return new_member
        
    def update_member_status(self, member_id: int, is_active: bool) -> CompanyMemberEntity:
        validate_company_member_status(is_active)

        with self.uow:
            member = self.uow.company_members.get(member_id)
            if not member:
                raise ValueError("Company member not found")
            company = self.uow.companies.get(member.company_id)
            if not company:
                raise ValueError("Company not found")
            if is_active and not company.is_active:
                raise ValueError("Cannot activate member of inactive company")
            member.is_active = is_active
            updated_member = self.uow.company_members.update(member)
            self.uow.commit()
            return updated_member
        
    def get_active_members_by_company(self, company_id: int) -> list[CompanyMemberEntity]:
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            return self.uow.company_members.get_all_active_by_company(company_id)

    def get_members_by_company(self, company_id: int) -> list[CompanyMemberEntity]:
        with self.uow:
            company = self.uow.companies.get(company_id)
            if not company:
                raise ValueError("Company not found")
            return self.uow.company_members.get_all_by_company(company_id)
    
    def get_active_members(self) -> list[CompanyMemberEntity]:
        with self.uow:
            return self.uow.company_members.get_all_active()
    
    def get_member(self, member_id: int) -> CompanyMemberEntity:
        with self.uow:
            member = self.uow.company_members.get(member_id)
            if not member:
                raise ValueError("Company member not found")
            return member
    
    def update_member_role(self, member_id: int, new_role: str) -> CompanyMemberEntity:
        normalized_role = validate_company_member_role(new_role)

        with self.uow:
            member = self.uow.company_members.get(member_id)
            if not member:
                raise ValueError("Company member not found")
            member.role = normalized_role
            updated_member = self.uow.company_members.update(member)
            self.uow.commit()
            return updated_member
        
