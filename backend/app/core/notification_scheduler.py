import logging
from datetime import datetime, date, timedelta
from threading import Event, Thread
from time import sleep

from sqlalchemy.orm import joinedload

from app.core.uow import SqlAlchemyUnitOfWork
from app.domain.models.notification import NotificationEntity
from app.infrastructure.database.database import SessionLocal
from app.infrastructure.database.tables import (
    ChargingSession as ChargingSessionModel,
    Reservation as ReservationModel,
)

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


def _calculate_consumed_energy(start_time, end_time, charging_power_kw: float) -> float:
    start_datetime = datetime.combine(date.today(), start_time)
    end_datetime = datetime.combine(date.today(), end_time)
    duration_hours = (end_datetime - start_datetime).total_seconds() / 3600
    return round(duration_hours * charging_power_kw, 3)


def _finish_expired_charging_sessions() -> None:
    now = datetime.now()
    with SessionLocal() as db:
        query = (
            db.query(ChargingSessionModel)
            .join(ReservationModel, ChargingSessionModel.reservation)
            .options(
                joinedload(ChargingSessionModel.reservation).joinedload(ReservationModel.vehicle),
                joinedload(ChargingSessionModel.reservation).joinedload(ReservationModel.charger),
            )
            .filter(
                ChargingSessionModel.status.in_(("STARTED", "IN_PROGRESS")),
                ReservationModel.date == now.date(),
                ReservationModel.end_time <= now.time(),
                ReservationModel.status.in_(("PENDING", "CONFIRMED")),
            )
        )
        sessions = query.all()

        if not sessions:
            return

        for session_model in sessions:
            reservation = session_model.reservation
            if not reservation or session_model.end_time is not None:
                continue

            vehicle = reservation.vehicle
            charger = reservation.charger
            if not vehicle or not charger:
                continue

            charging_power_kw = min(vehicle.max_charging_power, charger.max_power)
            session_model.end_time = reservation.end_time
            session_model.consuming_power = _calculate_consumed_energy(
                session_model.start_time,
                reservation.end_time,
                charging_power_kw,
            )
            session_model.cost = round(
                session_model.consuming_power * charger.price_per_kwh,
                2,
            )
            session_model.status = "COMPLETED"
            reservation.status = "COMPLETED"
            charger.status = "AVAILABLE"

        db.commit()


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
