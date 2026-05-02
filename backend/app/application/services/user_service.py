from app.core.uow import AbstractUnitOfWork
from app.domain.models.user import UserEntity
from typing import List, Optional

class UserService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_user(self, user: UserEntity) -> UserEntity:
        with self.uow:
            new_user = self.uow.users.add(user)
            self.uow.commit()
            return new_user

    def get_all_users(self) -> List[UserEntity]:
        with self.uow:
            return self.uow.users.list()

    def get_user(self, user_id: int) -> Optional[UserEntity]:
        with self.uow:
            return self.uow.users.get(user_id)

    def get_user_vehicles(self, user_id: int) -> List:
        with self.uow:
            user = self.uow.users.get(user_id)
            if not user:
                return []
            return self.uow.vehicles.list_by_user_id(user_id)
        
    def get_user_reservations(self, user_id: int) -> List:
        with self.uow:
            user = self.uow.users.get(user_id)
            if not user:
                return []
            return self.uow.reservations.list_by_user_id(user_id)