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
