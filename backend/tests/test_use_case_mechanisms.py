import unittest
from datetime import date, time, timedelta


from app.application.services.reservation_service import (
    ReservationConflictError,
    ReservationService,
)
from app.application.services.station_service import StationService
from app.domain.models.charger import ChargerEntity
from app.domain.models.reservation import ReservationEntity
from app.domain.models.station import StationEntity
from app.domain.models.user import UserEntity
from app.domain.models.vehicle import VehicleEntity


class DictRepo:
    def __init__(self, items=None):
        self.items = dict(items or {})
        self.added = []
        self.updated = []

    def get(self, item_id):
        return self.items.get(item_id)

    def add(self, entity):
        if entity.id is None:
            entity.id = max(self.items.keys(), default=0) + 1
        self.items[entity.id] = entity
        self.added.append(entity)
        return entity

    def update(self, entity):
        self.items[entity.id] = entity
        self.updated.append(entity)
        return entity

    def list(self):
        return list(self.items.values())

    def get_by_id(self, item_id):
        return self.get(item_id)


class ReservationRepo(DictRepo):
    blocking_statuses = {"PENDING", "CONFIRMED"}

    def list_by_user_id(self, user_id):
        return [item for item in self.items.values() if item.user_id == user_id]

    def list_by_user_and_date(self, user_id, reservation_date):
        return [
            item
            for item in self.items.values()
            if item.user_id == user_id
            and item.date == reservation_date
            and item.status in self.blocking_statuses
        ]

    def list_overlapping_by_charger(self, charger_id, reservation_date, start_time, end_time):
        return [
            item
            for item in self.items.values()
            if item.charger_id == charger_id
            and item.date == reservation_date
            and item.status in self.blocking_statuses
            and item.start_time < end_time
            and item.end_time > start_time
        ]

    def list_overlapping_by_user(self, user_id, reservation_date, start_time, end_time):
        return [
            item
            for item in self.items.values()
            if item.user_id == user_id
            and item.date == reservation_date
            and item.status in self.blocking_statuses
            and item.start_time < end_time
            and item.end_time > start_time
        ]

    def list_by_user_after_date(self, user_id, after_date):
        return [
            item
            for item in self.items.values()
            if item.user_id == user_id and item.date > after_date
        ]

    def get_expired_or_cancelled_count_last_2_months(self, user_id):
        return 0

    def exists_active_for_charger(self, charger_id, now):
        return False

    def list_active_for_chargers(self, charger_ids, now):
        return []


class StationRepo(DictRepo):
    def __init__(self, stations=None):
        super().__init__({station.id: station for station in stations or []})
        self.nearby = stations or []

    def list_nearby_in_area(self, north_latitude, south_latitude, east_longitude, west_longitude):
        return list(self.nearby)


class FakeUnitOfWork:
    def __init__(self, **repos):
        self.__dict__.update(repos)
        self.commits = 0
        self.rollbacks = 0

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.rollback()
        else:
            self.commit()

    def commit(self):
        self.commits += 1

    def rollback(self):
        self.rollbacks += 1


class FindChargingStationUseCaseTests(unittest.TestCase):
    def _vehicle(self):
        return VehicleEntity(
            id=1,
            user_id=10,
            name="Car",
            brand="Tesla",
            model="Model 3",
            plate="34 EV 001",
            max_charging_power=120,
            battery_capacity=75,
            connector_type="CCS2",
            current_type="DC",
        )

    def test_nearby_compatible_stations_return_only_matching_chargers(self):
        compatible = ChargerEntity(
            id=1,
            station_id=1,
            connector_type="CCS2",
            current_type="DC",
            status="AVAILABLE",
        )
        incompatible = ChargerEntity(
            id=2,
            station_id=1,
            connector_type="TYPE_2",
            current_type="AC",
            status="AVAILABLE",
        )
        station = StationEntity(
            id=1,
            company_id=1,
            name="Central",
            address="Main Street",
            latitude=41.0,
            longitude=29.0,
            chargers=[compatible, incompatible],
        )
        uow = FakeUnitOfWork(
            vehicles=DictRepo({1: self._vehicle()}),
            stations=StationRepo([station]),
            reservations=ReservationRepo(),
        )

        result = StationService(uow).get_nearby_compatible_stations(
            north_latitude=42,
            south_latitude=40,
            east_longitude=30,
            west_longitude=28,
            vehicle_id=1,
            current_user_id=10,
        )

        self.assertEqual(len(result), 1)
        self.assertEqual([charger.id for charger in result[0].chargers], [1])

    def test_incompatible_or_missing_nearby_stations_return_empty_list(self):
        incompatible_station = StationEntity(
            id=1,
            company_id=1,
            name="AC Only",
            address="Main Street",
            latitude=41.0,
            longitude=29.0,
            chargers=[
                ChargerEntity(
                    id=1,
                    station_id=1,
                    connector_type="TYPE_2",
                    current_type="AC",
                )
            ],
        )

        for stations in ([incompatible_station], []):
            with self.subTest(stations=len(stations)):
                uow = FakeUnitOfWork(
                    vehicles=DictRepo({1: self._vehicle()}),
                    stations=StationRepo(stations),
                    reservations=ReservationRepo(),
                )
                result = StationService(uow).get_nearby_compatible_stations(
                    42, 40, 30, 28, 1, 10
                )
                self.assertEqual(result, [])


class ReservationUseCaseTests(unittest.TestCase):
    def setUp(self):
        self.reservation_date = date.today() + timedelta(days=1)
        self.user = UserEntity(id=10, name="Ada", surname="Lovelace", email="ada@example.com")
        self.vehicle = VehicleEntity(
            id=1,
            user_id=10,
            name="Car",
            brand="Tesla",
            model="Model 3",
            plate="34 EV 001",
            max_charging_power=120,
            battery_capacity=75,
            connector_type="CCS2",
            current_type="DC",
        )
        self.charger = ChargerEntity(
            id=1,
            station_id=1,
            connector_type="CCS2",
            current_type="DC",
            status="AVAILABLE",
        )
        self.station = StationEntity(
            id=1,
            company_id=1,
            name="Central",
            address="Main Street",
            latitude=41.0,
            longitude=29.0,
            status="AVAILABLE",
        )

    def _uow(self, reservations=None):
        return FakeUnitOfWork(
            users=DictRepo({10: self.user, 11: UserEntity(id=11, name="Grace", surname="Hopper", email="grace@example.com")}),
            vehicles=DictRepo({1: self.vehicle}),
            chargers=DictRepo({1: self.charger}),
            stations=DictRepo({1: self.station}),
            reservations=ReservationRepo({item.id: item for item in reservations or []}),
        )

    def _reservation(self, start_time=time(10, 0), user_id=10, status="PENDING", item_id=None):
        return ReservationEntity(
            id=item_id,
            user_id=user_id,
            vehicle_id=1,
            charger_id=1,
            station_id=1,
            date=self.reservation_date,
            start_time=start_time,
            end_time=time(start_time.hour + 2, start_time.minute),
            status=status,
        )

    def test_valid_reservation_is_created_and_slot_becomes_blocking(self):
        uow = self._uow()
        created = ReservationService(uow).create_reservation(
            self._reservation(),
            current_user_id=10,
        )

        self.assertEqual(created.status, "PENDING")
        self.assertEqual(len(uow.reservations.added), 1)
        self.assertTrue(
            uow.reservations.list_overlapping_by_charger(
                1, self.reservation_date, time(10, 30), time(11, 30)
            )
        )

    def test_busy_slot_reservation_is_rejected(self):
        existing = self._reservation(item_id=1, user_id=11, start_time=time(10, 0))
        uow = self._uow([existing])

        with self.assertRaises(ReservationConflictError):
            ReservationService(uow).create_reservation(
                self._reservation(start_time=time(10, 30)),
                current_user_id=10,
            )

        self.assertEqual(uow.reservations.added, [])

    def test_cancelled_reservation_does_not_block_slot_again(self):
        cancelled = self._reservation(item_id=1, start_time=time(10, 0), status="CANCELLED")
        uow = self._uow([cancelled])

        created = ReservationService(uow).create_reservation(
            self._reservation(start_time=time(10, 30)),
            current_user_id=10,
        )

        self.assertEqual(created.status, "PENDING")
        self.assertEqual(len(uow.reservations.added), 1)

    def test_user_can_cancel_own_active_reservation(self):
        existing = self._reservation(item_id=1, start_time=time(10, 0))
        uow = self._uow([existing])

        updated = ReservationService(uow).update_reservation_status(
            reservation_id=1,
            status="CANCELLED",
            current_user_id=10,
        )

        self.assertEqual(updated.status, "CANCELLED")
        self.assertEqual(uow.reservations.get(1).status, "CANCELLED")

    def test_cancelled_reservation_slot_can_be_reserved_again(self):
        existing = self._reservation(item_id=1, start_time=time(10, 0))
        uow = self._uow([existing])
        service = ReservationService(uow)
        service.update_reservation_status(
            reservation_id=1,
            status="CANCELLED",
            current_user_id=10,
        )

        created = service.create_reservation(
            self._reservation(start_time=time(10, 0)),
            current_user_id=10,
        )

        self.assertEqual(created.status, "PENDING")
        self.assertEqual(len(uow.reservations.added), 1)

    def test_station_not_available_rejects_reservation(self):
        self.station.status = "MAINTENANCE"
        uow = self._uow()

        with self.assertRaisesRegex(ValueError, "Station is not available"):
            ReservationService(uow).create_reservation(
                self._reservation(),
                current_user_id=10,
            )

        self.assertEqual(uow.reservations.added, [])

    def test_charger_not_available_rejects_reservation(self):
        self.charger.status = "OCCUPIED"
        uow = self._uow()

        with self.assertRaisesRegex(ValueError, "Charger is not available"):
            ReservationService(uow).create_reservation(
                self._reservation(),
                current_user_id=10,
            )

        self.assertEqual(uow.reservations.added, [])


if __name__ == "__main__":
    unittest.main()





