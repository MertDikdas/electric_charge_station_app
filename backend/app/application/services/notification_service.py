from datetime import datetime, timedelta
from typing import List, Optional

from app.core.uow import AbstractUnitOfWork
from app.domain.models.notification import NotificationEntity


REMINDER_WINDOW_MINUTES = 30


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

    def _create_reservation_reminder(self, reservation) -> None:
        title = "Upcoming charging reservation"
        message = (
            f"Your charging station reservation at charger {reservation.charger_id} "
            f"starts at {reservation.start_time.strftime('%H:%M')} on {reservation.date:%Y-%m-%d}. "
            "You will be reminded 30 minutes before your session begins."
        )

        if self.uow.notifications.exists_by_user_and_title_and_message(
            reservation.user_id,
            title,
            message,
        ):
            return

        reminder = NotificationEntity(
            user_id=reservation.user_id,
            title=title,
            message=message,
            notification_type="INFO",
        )
        self.uow.notifications.add(reminder)

    def _ensure_reservation_reminders(self, user_id: int) -> None:
        now = datetime.utcnow()
        end_time = now + timedelta(minutes=REMINDER_WINDOW_MINUTES)
        reservations = self.uow.reservations.list_starting_between(now, end_time)
        for reservation in reservations:
            if reservation.user_id == user_id:
                self._create_reservation_reminder(reservation)

    def get_user_notifications(
        self,
        user_id: int,
        unread_only: bool = False,
    ) -> List[NotificationEntity]:
        with self.uow:
            user = self.uow.users.get(user_id)
            if not user:
                raise LookupError("User not found")
            self._ensure_reservation_reminders(user_id)
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
