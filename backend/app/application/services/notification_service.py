from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.notification import NotificationEntity


class NotificationService:
    allowed_types = {"INFO", "SUCCESS", "WARNING", "ERROR"}

    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_notification(self, notification: NotificationEntity) -> NotificationEntity:
        with self.uow:
            notification.notification_type = notification.notification_type.upper()
            self._validate_notification(notification)
            new_notification = self.uow.notifications.add(notification)
            self.uow.commit()
            return new_notification

    def get_all_notifications(self) -> List[NotificationEntity]:
        with self.uow:
            return self.uow.notifications.list()

    def get_notification(self, notification_id: int) -> Optional[NotificationEntity]:
        with self.uow:
            return self.uow.notifications.get(notification_id)

    def get_user_notifications(
        self,
        user_id: int,
        unread_only: bool = False,
    ) -> List[NotificationEntity]:
        with self.uow:
            user = self.uow.users.get(user_id)
            if not user:
                raise LookupError("User not found")
            if unread_only:
                return self.uow.notifications.list_unread_by_user_id(user_id)
            return self.uow.notifications.list_by_user_id(user_id)

    def mark_notification_as_read(
        self,
        notification_id: int,
    ) -> Optional[NotificationEntity]:
        with self.uow:
            notification = self.uow.notifications.mark_as_read(notification_id)
            if notification:
                self.uow.commit()
            return notification

    def delete_notification(self, notification_id: int) -> bool:
        with self.uow:
            notification = self.uow.notifications.get(notification_id)
            if not notification:
                return False
            self.uow.notifications.delete(notification)
            self.uow.commit()
            return True

    def _validate_notification(self, notification: NotificationEntity) -> None:
        user = self.uow.users.get(notification.user_id)
        if not user:
            raise LookupError("User not found")

        if notification.notification_type not in self.allowed_types:
            raise ValueError("Notification type must be INFO, SUCCESS, WARNING, or ERROR")
