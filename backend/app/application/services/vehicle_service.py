from app.models.user import UserCreate, User
from app.core.uow import AbstractUnitOfWork
from typing import List, Optional

class UserService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_user(self, user_in: UserCreate) -> User:
        with self.uow:
            new_user = User(**user_in.model_dump(), id=0)
            self.uow.users.add(new_user)
            self.uow.commit()
            return new_user

    def get_all_users(self) -> List[User]:
        with self.uow:
            return self.uow.users.list()

    def get_user(self, user_id: int) -> Optional[User]:
        with self.uow:
            return self.uow.users.get(user_id)
