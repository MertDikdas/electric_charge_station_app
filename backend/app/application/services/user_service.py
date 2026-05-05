from app.core.uow import AbstractUnitOfWork
from app.domain.models.user import UserEntity
from typing import List, Optional
from app.domain.rules.user_rules import (
    validate_user_email,
    validate_user_password,
    validate_balance,
)


class UserService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_user(self, user: UserEntity) -> UserEntity:
        with self.uow:
            self._validate_user(user)
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

    def get_user_charging_sessions(self, user_id: int) -> List:
        with self.uow:
            user = self.uow.users.get(user_id)
            if not user:
                return []
            return self.uow.charging_sessions.list_by_user_id(user_id)
        
    def delete_user(self, user_id: int) -> None:
        with self.uow:
            user = self.uow.users.get(user_id)
            if user:
                self.uow.users.delete(user_id)
                self.uow.commit()

    def get_user_by_email(self, email: str) -> Optional[UserEntity]:
        with self.uow:
            return self.uow.users.get_by_email(email)

    def _validate_user(self, user: UserEntity) -> None:
        if not validate_user_email(user):
            raise ValueError("Invalid email format")
        if not validate_user_password(user):
            raise ValueError("Password does not meet requirements")
        if not validate_balance(user):
            raise ValueError("Balance cannot be negative")