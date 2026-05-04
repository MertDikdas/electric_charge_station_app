from abc import abstractmethod
from typing import Generic, List, Optional, Type, TypeVar

from sqlalchemy.orm import Session

from app.infrastructure.repositories.abstract.base import AbstractRepository

EntityT = TypeVar("EntityT")
ModelT = TypeVar("ModelT")


class SqlAlchemyRepository(AbstractRepository[EntityT], Generic[EntityT, ModelT]):
    model: Type[ModelT]

    def __init__(self, session: Session):
        self.session = session

    @abstractmethod
    def to_model(self, entity: EntityT) -> ModelT:
        raise NotImplementedError

    @abstractmethod
    def to_entity(self, model: ModelT) -> EntityT:
        raise NotImplementedError

    def add(self, entity: EntityT) -> EntityT:
        model = self.to_model(entity)
        self.session.add(model)
        self.session.flush()
        return self.to_entity(model)

    def get(self, id: int) -> Optional[EntityT]:
        model = self.session.get(self.model, id)
        if model is None:
            return None
        return self.to_entity(model)

    def list(self) -> List[EntityT]:
        return [self.to_entity(model) for model in self.session.query(self.model).all()]

    def delete(self, entity: EntityT) -> None:
        entity_id = getattr(entity, "id", None)
        if entity_id is None:
            return

        model = self.session.get(self.model, entity_id)
        if model is not None:
            self.session.delete(model)

    def update(self, entity: EntityT) -> EntityT:
        model = self.to_model(entity)
        self.session.merge(model)
        self.session.flush()
        return self.to_entity(model)
