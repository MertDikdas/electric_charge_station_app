from abc import ABC, abstractmethod
from typing import List, Generic, TypeVar, Optional

T = TypeVar("T")

class AbstractRepository(ABC, Generic[T]):
    @abstractmethod
    def add(self, entity: T):
        raise NotImplementedError

    @abstractmethod
    def get(self, id: int) -> Optional[T]:
        raise NotImplementedError

    @abstractmethod
    def list(self) -> List[T]:
        raise NotImplementedError

# Frontend'in test edebilmesi için geçici in-memory repository
class InMemoryRepository(AbstractRepository[T]):
    def __init__(self):
        self._items = []
        self._id_counter = 1

    def add(self, entity: T):
        entity.id = self._id_counter
        self._items.append(entity)
        self._id_counter += 1

    def get(self, id: int) -> Optional[T]:
        return next((item for item in self._items if getattr(item, 'id', None) == id), None)

    def list(self) -> List[T]:
        return self._items
