from datetime import datetime, timedelta
from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.auth_response import AuthResponseEntity
from app.domain.models.user_session import UserSessionEntity
from app.domain.models.user import UserEntity
from app.core.security import ACCESS_TOKEN_EXPIRE_DAYS, verify_password, create_access_token
from typing import List, Optional
from app.domain.rules.user_rules import (
    validate_user_email,
    validate_user_password,
    validate_balance,
)


class UserService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_user(self, user: UserEntity) -> AuthResponseEntity:
        with self.uow:
            self._validate_user(user)
            new_user = self.uow.users.add(user)
            if new_user.id is None:
                raise RuntimeError("User id was not generated after saving user")

            access_token = self._create_session(new_user)
            self.uow.commit()

            return AuthResponseEntity(access_token=access_token, user=new_user)
        
    def login_user(self, email: str, password: str) -> Optional[AuthResponseEntity]:
        with self.uow:
            user = self.uow.users.get_by_email(email)
            if not user or not verify_password(password, user.password_hash):
                return None

            access_token = self._create_session(user)
            self.uow.commit()

            return AuthResponseEntity(access_token=access_token, user=user)

    def logout_user(self, token: str) -> bool:
        with self.uow:
            revoked = self.uow.user_sessions.revoke_token(token)
            self.uow.commit()
            return revoked

    def _create_session(self, user: UserEntity) -> str:
        created_at = datetime.utcnow()
        expires_delta = timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
        expires_at = created_at + expires_delta
        access_token = create_access_token(
            data={"sub": user.email, "user_id": user.id},
            expires_delta=expires_delta,
        )

        self.uow.user_sessions.add(
            UserSessionEntity(
                id=None,
                user_id=user.id,
                token=access_token,
                created_at=created_at,
                expires_at=expires_at,
            )
        )

        return access_token


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

    def add_balance(self, user_id: int, amount: float) -> Optional[UserEntity]:
        with self.uow:
            user = self.uow.users.get(user_id)
            if not user:
                return None
            if amount < 0:
                raise ValueError("Amount must be positive")
            user.balance = round(user.balance + amount, 2)
            updated_user = self.uow.users.update(user)
            self.uow.commit()
            return updated_user
        
    def _validate_user(self, user: UserEntity) -> None:
        if not validate_user_email(user):
            raise ValueError("Invalid email format")
        if not validate_user_password(user):
            raise ValueError("Password does not meet requirements")
        if not validate_balance(user):
            raise ValueError("Balance cannot be negative")
        
    