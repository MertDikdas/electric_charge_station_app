from app.core.uow import AbstractUnitOfWork
from app.domain.rules.charger_rules import is_charger_available
from app.domain.models.charger import ChargerEntity
from typing import List, Optional, Dict, Any
from datetime import date, time, timedelta


class ChargerService:
    allowed_statuses = {"AVAILABLE", "OCCUPIED", "OUT_OF_SERVICE", "MAINTENANCE", "CLOSED"}

    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow

    def create_charger(self, charger: ChargerEntity) -> ChargerEntity:
        with self.uow:
            charger.status = charger.status.upper()
            new_charger = self.uow.chargers.add(charger)
            self.uow.commit()
            return new_charger

    def get_all_chargers(self) -> List[ChargerEntity]:
        with self.uow:
            return self.uow.chargers.list()

    def get_charger(self, charger_id: int) -> Optional[ChargerEntity]:
        with self.uow:
            return self.uow.chargers.get(charger_id)

    def update_charger(self, charger: ChargerEntity) -> ChargerEntity:
        with self.uow:
            charger.status = charger.status.upper()
            updated_charger = self.uow.chargers.update(charger)
            self.uow.commit()
            return updated_charger

    def delete_charger(self, charger_id: int) -> None:
        with self.uow:
            charger = self.uow.chargers.get(charger_id)
            if charger:
                self.uow.chargers.delete(charger)
                self.uow.commit()

    def update_charger_status(self, charger_id: int, status: str) -> Optional[ChargerEntity]:
        with self.uow:
            normalized_status = status.upper()
            if normalized_status not in self.allowed_statuses:
                raise ValueError("Invalid charger status")

            charger = self.uow.chargers.get(charger_id)
            if charger:
                charger.status = normalized_status
                updated_charger = self.uow.chargers.update(charger)
                self.uow.commit()
                return updated_charger
            return None

    def get_charger_availability(
        self, charger_id: int, start_date: date, end_date: date
    ) -> List[Dict[str, Any]]:
        with self.uow:
            charger = self.uow.chargers.get(charger_id)
            if not charger:
                raise LookupError("Charger not found")

            if not is_charger_available(charger):
                return []

            availability = []
            current_date = start_date
            while current_date <= end_date:
                # Get reservations for this date
                reservations = self.uow.reservations.list_by_charger_and_date(
                    charger_id, current_date
                )
                
                # Simple availability: assume 24 hours, mark reserved times as unavailable
                # In a real implementation, this would be more sophisticated
                day_slots = []
                for hour in range(24):
                    start_time = time(hour, 0)
                    end_time = time((hour + 1) % 24, 0) if hour < 23 else time(23, 59)
                    
                    is_available = True
                    for res in reservations:
                        if res.start_time < end_time and res.end_time > start_time:
                            is_available = False
                            break
                    
                    day_slots.append({
                        "start_time": start_time.isoformat(),
                        "end_time": end_time.isoformat(),
                        "available": is_available
                    })
                
                availability.append({
                    "date": current_date.isoformat(),
                    "slots": day_slots
                })
                current_date += timedelta(days=1)
            
            return availability
