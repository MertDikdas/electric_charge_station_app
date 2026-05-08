from abc import abstractmethod
from typing import List

from app.domain.models.notification import NotificationEntity
from app.infrastructure.repositories.abstract.base import AbstractRepository


class AbstractNotificationRepository(AbstractRepository[NotificationEntity]):
    @abstractmethod
    def list_by_user_id(self, user_id: int) -> List[NotificationEntity]:
        raise NotImplementedError

    @abstractmethod
    def list_unread_by_user_id(self, user_id: int) -> List[NotificationEntity]:
        raise NotImplementedError

    @abstractmethod
    def exists_by_user_and_title_and_message(
        self,
        user_id: int,
        title: str,
        message: str,
    ) -> bool:
        raise NotImplementedError

    @abstractmethod
    def mark_as_read(self, notification_id: int) -> NotificationEntity | None:
        raise NotImplementedError
