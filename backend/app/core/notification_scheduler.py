import logging
from datetime import datetime, timedelta
from threading import Event, Thread

from app.application.services.charger_session_service import ChargingSessionService
from app.core.uow import SqlAlchemyUnitOfWork
from app.domain.models.notification import NotificationEntity
from app.infrastructure.database.database import SessionLocal

logger = logging.getLogger(__name__)

_scheduler_thread: Thread | None = None
_scheduler_stop_event = Event()

REMINDER_WINDOW_MINUTES = 30
SCHEDULER_LOOP_SECONDS = 60


def _format_reservation_reminder_title() -> str:
    return "Upcoming charging reservation"


def _format_reservation_reminder_message(reservation) -> str:
    return (
        f"Your charging station reservation at charger {reservation.charger_id} "
        f"starts at {reservation.start_time.strftime('%H:%M')} on {reservation.date:%Y-%m-%d}. "
        "You will be reminded 30 minutes before your session begins."
    )


def _should_create_reminder(uow: SqlAlchemyUnitOfWork, reservation) -> bool:
    title = _format_reservation_reminder_title()
    message = _format_reservation_reminder_message(reservation)
    return not uow.notifications.exists_by_user_and_title_and_message(
        reservation.user_id,
        title,
        message,
    )


def _create_reservation_reminder(uow: SqlAlchemyUnitOfWork, reservation) -> None:
    if not _should_create_reminder(uow, reservation):
        return

    title = _format_reservation_reminder_title()
    message = _format_reservation_reminder_message(reservation)

    reminder = NotificationEntity(
        user_id=reservation.user_id,
        title=title,
        message=message,
        notification_type="INFO",
    )
    uow.notifications.add(reminder)
    uow.commit()


def _find_upcoming_reservations() -> list:
    now = datetime.utcnow()
    start_window = now + timedelta(minutes=REMINDER_WINDOW_MINUTES)
    end_window = start_window + timedelta(seconds=SCHEDULER_LOOP_SECONDS)

    with SessionLocal() as db:
        uow = SqlAlchemyUnitOfWork(db)
        return uow.reservations.list_starting_between(start_window, end_window)


def _finish_expired_charging_sessions() -> None:
    now = datetime.now()
    with SessionLocal() as db:
        uow = SqlAlchemyUnitOfWork(db)
        expired_sessions = uow.charging_sessions.list_expired_for_auto_finish(now)

        if not expired_sessions:
            return

        service = ChargingSessionService(uow)
        for expired_session in expired_sessions:
            try:
                service.finish_session(
                    session_id=expired_session.reservation_id,
                    current_user_id=expired_session.user_id,
                    is_staff=True,
                    end_time=expired_session.end_time,
                )
            except Exception as exc:
                logger.exception(
                    "Failed to finish expired charging session %s: %s",
                    expired_session.reservation_id,
                    exc,
                )


def _run_scheduler() -> None:
    logger.info("Starting reservation reminder scheduler")
    while not _scheduler_stop_event.is_set():
        try:
            reservations = _find_upcoming_reservations()
            if reservations:
                with SessionLocal() as db:
                    uow = SqlAlchemyUnitOfWork(db)
                    for reservation in reservations:
                        _create_reservation_reminder(uow, reservation)

            _finish_expired_charging_sessions()
        except Exception as exc:
            logger.exception("Reservation reminder scheduler failed: %s", exc)
        _scheduler_stop_event.wait(SCHEDULER_LOOP_SECONDS)
    logger.info("Stopping reservation reminder scheduler")


def start_notification_scheduler() -> None:
    global _scheduler_thread
    if _scheduler_thread is not None and _scheduler_thread.is_alive():
        return

    _scheduler_stop_event.clear()
    _scheduler_thread = Thread(target=_run_scheduler, daemon=True)
    _scheduler_thread.start()


def stop_notification_scheduler() -> None:
    _scheduler_stop_event.set()
    if _scheduler_thread is not None:
        _scheduler_thread.join(timeout=5)
