import os
from openai import OpenAI
from app.core.uow import AbstractUnitOfWork
from typing import Any

class ChatbotService:
    def __init__(self, uow: AbstractUnitOfWork):
        self.uow = uow
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

    def build_user_context(self, user_id: int) -> dict[str, Any]:
        with self.uow:
            user = self.uow.users.get(user_id)
            vehicles = self.uow.vehicles.list_by_user_id(user_id)
            reservations = self.uow.reservations.list_by_user_id(user_id)
            stations = self.uow.stations.list()

            active_vehicle = next(
                (vehicle for vehicle in vehicles if vehicle.is_active),
                vehicles[0] if vehicles else None,
            )

            compatible_stations = []

            if active_vehicle:
                for station in stations:
                    chargers = self.uow.chargers.list_by_station(station.id)

                    compatible_chargers = [
                        charger
                        for charger in chargers
                        if charger.connector_type == active_vehicle.connector_type
                        and charger.current_type == active_vehicle.current_type
                    ]

                    if not compatible_chargers:
                        continue

                    available_compatible_chargers = [
                        charger
                        for charger in compatible_chargers
                        if charger.status == "AVAILABLE"
                    ]

                    compatible_stations.append(
                        {
                            "company": station.company,
                            "address": station.address,
                            "latitude": station.latitude,
                            "longitude": station.longitude,
                            "status": station.status,
                            "compatible_charger_count": len(compatible_chargers),
                            "available_compatible_charger_count": len(available_compatible_chargers),
                            "min_price_per_kwh": min(
                                charger.price_per_kwh for charger in compatible_chargers
                            ),
                            "max_power": max(
                                charger.max_power for charger in compatible_chargers
                            ),
                        }
                    )
                    payments = self.uow.payments.get_by_user_id(user_id)

            return {
                "user": {
                    "email": getattr(user, "email", None) if user else None,
                    "balance": getattr(user, "balance", None) if user else None,
                },
                "vehicles": [
                    {
                        "model": vehicle.model,
                        "plate": vehicle.plate,
                        "connector_type": vehicle.connector_type,
                        "current_type": vehicle.current_type,
                        "battery_capacity": vehicle.battery_capacity,
                        "max_charging_power": vehicle.max_charging_power,
                        "is_active": vehicle.is_active,
                    }
                    for vehicle in vehicles
                ],
                "active_vehicle": {
                    "model": active_vehicle.model,
                    "connector_type": active_vehicle.connector_type,
                    "current_type": active_vehicle.current_type,
                    "battery_capacity": active_vehicle.battery_capacity,
                    "max_charging_power": active_vehicle.max_charging_power,
                }
                if active_vehicle
                else None,
                "recent_reservations": [
                    {
                        "vehicle_name": self.uow.vehicles.get_by_id(reservation.vehicle_id).model,
                        "charger_id": self.uow.stations.get(self.uow.chargers.get(reservation.charger_id).station_id).address,
                        "date": str(reservation.date),
                        "start_time": str(reservation.start_time),
                        "end_time": str(reservation.end_time),
                        "status": reservation.status,
                    }
                    for reservation in reservations[-5:]
                ],
                "payments": [
                    {
                        "amount": payment.amount,
                        "status": payment.status,
                        "date": payment.payment_date,
                    }
                    for payment in payments
                ],
                "compatible_stations": compatible_stations[:10],
            }

    def ask(self, message: str, user_context: dict[str, Any]) -> str:
        system_prompt = """
You are an AI customer support assistant for an EV Charging Station app.

You can help users with:
- finding compatible charging stations
- explaining reservations
- helping with charging session questions
- answering payment and wallet questions
- explaining how to use the app

Use the provided user context when answering.
Do not invent station, vehicle, reservation, charger, or payment data.
If the required information is not in the context, say that it is not available.
Keep answers short, clear, and helpful.
"""

        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "system", "content": f"User context: {user_context}"},
                {"role": "user", "content": message},
            ],
            temperature=0.3,
        )

        return response.choices[0].message.content