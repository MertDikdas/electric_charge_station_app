from dataclasses import dataclass, field
from datetime import datetime

from app.domain.models.base import BaseEntity


@dataclass
class NotificationEntity(BaseEntity):
    user_id: int
    title: str
    message: str
    notification_type: str = "INFO"
    is_read: bool = False
    created_at: datetime = field(default_factory=datetime.utcnow)


Notification = NotificationEntity
