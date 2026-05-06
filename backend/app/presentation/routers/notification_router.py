from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query

from app.application.services.notification_service import NotificationService
from app.core.dependencies import (
    AuthenticatedUser,
    get_admin_or_station_manager,
    get_current_user,
    get_notification_service,
)
from app.domain.models.notification import NotificationEntity
from app.schemas.notification import Notification, NotificationCreate

router = APIRouter()


@router.post("", response_model=Notification, status_code=201)
def create_notification(
    notification: NotificationCreate,
    service: NotificationService = Depends(get_notification_service),
):
    notification_entity = NotificationEntity(**notification.model_dump())
    try:
        return service.create_notification(notification_entity)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/me", response_model=List[Notification])
def get_notifications(
    service: NotificationService = Depends(get_notification_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
    unread_only: bool = Query(default=False),
):
    try:
        return service.get_user_notifications(current_user.id, unread_only)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/all", response_model=List[Notification])
def get_all_notifications(
    service: NotificationService = Depends(get_notification_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    return service.get_all_notifications()


@router.get("/{notification_id}", response_model=Notification)
def get_notification(
    notification_id: int,
    service: NotificationService = Depends(get_notification_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    notification = service.get_notification(notification_id)
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    if notification.user_id != current_user.id and not current_user.is_staff:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return notification


@router.patch("/{notification_id}/read", response_model=Notification)
def mark_notification_as_read(
    notification_id: int,
    service: NotificationService = Depends(get_notification_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    notification = service.get_notification(notification_id)
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    if notification.user_id != current_user.id and not current_user.is_staff:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    updated_notification = service.mark_notification_as_read(notification_id)
    if not updated_notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return updated_notification


@router.delete("/{notification_id}", status_code=204)
def delete_notification(
    notification_id: int,
    service: NotificationService = Depends(get_notification_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    notification = service.get_notification(notification_id)
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    if notification.user_id != current_user.id and not current_user.is_staff:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    service.delete_notification(notification_id)
