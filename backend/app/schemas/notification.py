from datetime import datetime

from pydantic import BaseModel


class NotificationCreate(BaseModel):
    user_id: int
    title: str
    message: str
    notification_type: str = "INFO"


class NotificationUpdate(BaseModel):
    is_read: bool


class Notification(NotificationCreate):
    id: int
    is_read: bool = False
    created_at: datetime

    class Config:
        from_attributes = True
