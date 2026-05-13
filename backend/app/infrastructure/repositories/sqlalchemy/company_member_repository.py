from typing import Optional

from app.domain.models.company_member import CompanyMemberEntity
from app.infrastructure.database.tables import CompanyMember as CompanyMemberModel
from app.infrastructure.repositories.abstract.company_member_repository import AbstractCompanyMemberRepository
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository

class SqlAlchemyCompanyMemberRepository(SqlAlchemyRepository[CompanyMemberEntity, CompanyMemberModel], AbstractCompanyMemberRepository):
    model = CompanyMemberModel

    def to_model(self, entity: CompanyMemberEntity) -> CompanyMemberModel:
        return CompanyMemberModel(
            id=entity.id,
            company_id=entity.company_id,
            user_id=entity.user_id,
            role=entity.role.upper(),
            is_active=entity.is_active,
        )

    def to_entity(self, model: CompanyMemberModel) -> CompanyMemberEntity:
        return CompanyMemberEntity(
            id=model.id,
            company_id=model.company_id,
            user_id=model.user_id,
            role=model.role,
            is_active=model.is_active,
        )

    def get_by_company_and_user(self, company_id: int, user_id: int) -> Optional[CompanyMemberEntity]:
        model = self.session.query(CompanyMemberModel).filter(
            CompanyMemberModel.company_id == company_id,
            CompanyMemberModel.user_id == user_id
        ).first()
        if model is None:
            return None
        return self.to_entity(model)

    def get_all_active_by_company(self, company_id: int) -> list[CompanyMemberEntity]:
        models = self.session.query(CompanyMemberModel).filter(
            CompanyMemberModel.company_id == company_id,
            CompanyMemberModel.is_active.is_(True)
        ).all()
        return [self.to_entity(model) for model in models]

    def get_all_by_company(self, company_id: int) -> list[CompanyMemberEntity]:
        models = self.session.query(CompanyMemberModel).filter(
            CompanyMemberModel.company_id == company_id
        ).all()
        return [self.to_entity(model) for model in models]

    def get_all_active(self) -> list[CompanyMemberEntity]:
        models = self.session.query(CompanyMemberModel).filter(CompanyMemberModel.is_active.is_(True)).all()
        return [self.to_entity(model) for model in models]
    
    def deactivate_by_user_id(self, user_id: int) -> None:
        self.session.query(CompanyMemberModel).filter(
            CompanyMemberModel.user_id == user_id,
            CompanyMemberModel.is_active.is_(True),
        ).update(
            {CompanyMemberModel.is_active: False},
            synchronize_session=False,
        )

    def deactivate_by_company_id(self, company_id: int) -> None:
        self.session.query(CompanyMemberModel).filter(
            CompanyMemberModel.company_id == company_id,
            CompanyMemberModel.is_active.is_(True),
        ).update(
            {CompanyMemberModel.is_active: False},
            synchronize_session=False,
        )
