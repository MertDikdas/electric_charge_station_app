from abc import ABC, abstractmethod
from typing import Generic, List, Optional, TypeVar

T = TypeVar("T")


class AbstractRepository(ABC, Generic[T]):
    @abstractmethod
    def add(self, entity: T) -> T:
        raise NotImplementedError

    @abstractmethod
    def get(self, id: int) -> Optional[T]:
        raise NotImplementedError

    @abstractmethod
    def list(self) -> List[T]:
        raise NotImplementedError

    @abstractmethod
    def delete(self, entity: T) -> None:
        raise NotImplementedError
