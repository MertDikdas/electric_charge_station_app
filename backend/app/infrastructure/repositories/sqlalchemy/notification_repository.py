from typing import List

from app.domain.models.notification import NotificationEntity
from app.infrastructure.database.tables import Notification as NotificationModel
from app.infrastructure.repositories.abstract.notification_repository import (
    AbstractNotificationRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyNotificationRepository(
    SqlAlchemyRepository[NotificationEntity, NotificationModel],
    AbstractNotificationRepository,
):
    model = NotificationModel

    def to_model(self, entity: NotificationEntity) -> NotificationModel:
        return NotificationModel(
            id=entity.id,
            user_id=entity.user_id,
            title=entity.title,
            message=entity.message,
            notification_type=entity.notification_type.upper(),
            is_read=entity.is_read,
            created_at=entity.created_at,
        )

    def to_entity(self, model: NotificationModel) -> NotificationEntity:
        return NotificationEntity(
            id=model.id,
            user_id=model.user_id,
            title=model.title,
            message=model.message,
            notification_type=model.notification_type,
            is_read=model.is_read,
            created_at=model.created_at,
        )

    def list_by_user_id(self, user_id: int) -> List[NotificationEntity]:
        models = (
            self.session.query(NotificationModel)
            .filter(NotificationModel.user_id == user_id)
            .order_by(NotificationModel.created_at.desc())
            .all()
        )
        return [self.to_entity(model) for model in models]

    def list_unread_by_user_id(self, user_id: int) -> List[NotificationEntity]:
        models = (
            self.session.query(NotificationModel)
            .filter(
                NotificationModel.user_id == user_id,
                NotificationModel.is_read.is_(False),
            )
            .order_by(NotificationModel.created_at.desc())
            .all()
        )
        return [self.to_entity(model) for model in models]

    def exists_by_user_and_title_and_message(
        self,
        user_id: int,
        title: str,
        message: str,
    ) -> bool:
        existing = (
            self.session.query(NotificationModel)
            .filter(
                NotificationModel.user_id == user_id,
                NotificationModel.title == title,
                NotificationModel.message == message,
            )
            .first()
        )
        return existing is not None

    def mark_as_read(self, notification_id: int) -> NotificationEntity | None:
        model = self.session.get(NotificationModel, notification_id)
        if model is None:
            return None
        model.is_read = True
        self.session.flush()
        return self.to_entity(model)
