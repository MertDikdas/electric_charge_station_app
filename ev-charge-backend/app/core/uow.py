from abc import ABC, abstractmethod
from app.core.repository import InMemoryRepository

class AbstractUnitOfWork(ABC):
    users: InMemoryRepository
    vehicles: InMemoryRepository
    stations: InMemoryRepository
    chargers: InMemoryRepository
    reservations: InMemoryRepository
    charging_sessions: InMemoryRepository

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            self.rollback()
        else:
            self.commit()

    @abstractmethod
    def commit(self):
        raise NotImplementedError

    @abstractmethod
    def rollback(self):
        raise NotImplementedError

# Veritabanı (SQLAlchemy) hazır olana kadar çalışacak geçici UoW
class InMemoryUnitOfWork(AbstractUnitOfWork):
    def __init__(self):
        # Gerçek veritabanı geldiğinde buraları SqlAlchemyRepository ile değiştireceksiniz.
        self.users = InMemoryRepository()
        self.vehicles = InMemoryRepository()
        self.stations = InMemoryRepository()
        self.chargers = InMemoryRepository()
        self.reservations = InMemoryRepository()
        self.charging_sessions = InMemoryRepository()

    def commit(self):
        # InMemory olduğu için commit işlemine gerek yok
        pass

    def rollback(self):
        pass
