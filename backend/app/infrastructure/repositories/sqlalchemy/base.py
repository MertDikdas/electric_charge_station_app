from typing import Generic, List, Optional, Type, TypeVar

from sqlalchemy.orm import Session

from app.infrastructure.repositories.abstract.base import AbstractRepository

T = TypeVar("T")


class SqlAlchemyRepository(AbstractRepository[T], Generic[T]):
    model: Type[T]

    def __init__(self, session: Session):
        self.session = session

    def add(self, entity: T) -> T:
        self.session.add(entity)
        self.session.flush()
        return entity

    def get(self, id: int) -> Optional[T]:
        return self.session.get(self.model, id)

    def list(self) -> List[T]:
        return self.session.query(self.model).all()

    def delete(self, entity: T) -> None:
        self.session.delete(entity)
