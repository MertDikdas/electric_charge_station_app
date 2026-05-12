import unittest
from datetime import date, time

from app.domain.models.reservation import ReservationEntity
from app.domain.rules.reservation_rules import validate_reservation_conflicts


class ReservationRulesTestCase(unittest.TestCase):
    def _reservation(
        self,
        start_time: time,
        end_time: time,
        charger_id: int = 1,
        user_id: int = 1,
    ) -> ReservationEntity:
        return ReservationEntity(
            id=0,
            user_id=user_id,
            vehicle_id=1,
            charger_id=charger_id,
            date=date(2026, 5, 12),
            start_time=start_time,
            end_time=end_time,
        )

    def test_valid_reservation_no_overlap(self) -> None:
        existing = [
            self._reservation(start_time=time(19, 15), end_time=time(21, 15)),
        ]
        new_reservation = self._reservation(
            start_time=time(21, 15),
            end_time=time(23, 15),
        )

        validate_reservation_conflicts(new_reservation, existing)

    def test_overlapping_reservation_rejected(self) -> None:
        existing = [
            self._reservation(start_time=time(19, 15), end_time=time(21, 15)),
        ]
        new_reservation = self._reservation(
            start_time=time(20, 0),
            end_time=time(22, 0),
        )

        with self.assertRaises(ValueError):
            validate_reservation_conflicts(new_reservation, existing)

    def test_edge_case_end_equals_new_start_allowed(self) -> None:
        existing = [
            self._reservation(start_time=time(19, 15), end_time=time(21, 15)),
        ]
        new_reservation = self._reservation(
            start_time=time(21, 15),
            end_time=time(23, 15),
        )

        validate_reservation_conflicts(new_reservation, existing)


if __name__ == "__main__":
    unittest.main()
