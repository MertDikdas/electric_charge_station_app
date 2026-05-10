from typing import Optional

from app.domain.models.company import CompanyEntity
from app.infrastructure.database.tables import Company as CompanyModel
from app.infrastructure.repositories.abstract.company_repository import AbstractCompanyRepository
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository

class SqlAlchemyCompanyRepository(SqlAlchemyRepository[CompanyEntity, CompanyModel], AbstractCompanyRepository):
    model = CompanyModel

    def to_model(self, entity: CompanyEntity) -> CompanyModel:
        return CompanyModel(
            id=entity.id,
            name=entity.name,
            tax_number=entity.tax_number,
            phone=entity.phone,
            email=entity.email,
            address=entity.address,
            is_active=entity.is_active,
        )

    def to_entity(self, model: CompanyModel) -> CompanyEntity:
        return CompanyEntity(
            id=model.id,
            name=model.name,
            tax_number=model.tax_number,
            phone=model.phone,
            email=model.email,
            address=model.address,
            is_active=model.is_active,
        )

    def get_by_name(self, name: str) -> Optional[CompanyEntity]:
        model = self.session.query(CompanyModel).filter(CompanyModel.name == name).first()
        if model is None:
            return None
        return self.to_entity(model)

    def get_all_active(self) -> list[CompanyEntity]:
        models = self.session.query(CompanyModel).filter(CompanyModel.is_active.is_(True)).all()
        return [self.to_entity(model) for model in models]