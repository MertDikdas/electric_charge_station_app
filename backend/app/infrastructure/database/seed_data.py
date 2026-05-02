from app.infrastructure.database.database import SessionLocal
from app.infrastructure.database.tables import Station, Charger, User, Vehicle, Reservation, ChargingSession
from datetime import date, datetime, time


def seed_data():
    db = SessionLocal()

    try:
        station1 = Station(
            company="Company1",
            location="Location1",
            address="Address1",
            status="AVAILABLE",
        )

        station2 = Station(
            company="Company2",
            location="Location2",
            address="Address2",
            status="AVAILABLE",
        )

        db.add_all([station1, station2])
        db.commit()

        db.refresh(station1)
        db.refresh(station2)

        chargers = [
            Charger(
                station_id=station1.id,
                connector_type="TYPE_2",
                current_type="AC",
                max_power=22.0,
                price_per_kwh=8.30,
                status="AVAILABLE",
            ),
            Charger(
                station_id=station1.id,
                connector_type="CCS2",
                current_type="DC",
                max_power=50.0,
                price_per_kwh=5.50,
                status="AVAILABLE",
            ),
            Charger(
                station_id=station2.id,
                connector_type="CHADEMO",
                current_type="DC",
                max_power=50.0,
                price_per_kwh=12.0,
                status="AVAILABLE",
            ),
            Charger(
                station_id=station2.id,
                connector_type="TYPE_1",
                current_type="AC",
                max_power=7.4,
                price_per_kwh=6.0,
                status="AVAILABLE",
            ),      
        ]

        db.add_all(chargers)
        db.commit()
        db.refresh(chargers[0])
        db.refresh(chargers[1])
        db.refresh(chargers[2])
        db.refresh(chargers[3])

        user1 = User(
            name="Mustafa",
            surname="Şengül",
            email="mustafa.sengul@example.com",
            password_hash="123456",
            balance=100.0, 
        )
        user2 = User(
            name="onur",
            surname="yavuz",
            email="onur.yavuz@example.com",
            password_hash="1234567",
            balance=0.0, 
        )
        db.add_all([user1, user2])
        db.commit()
        db.refresh(user1)
        db.refresh(user2)

        vehicles = [
            Vehicle(
                user_id=user1.id,
                plate="34ABC123",
                model="Model S",
                is_active=True,
                current_type="DC",
                connector_type="CCS2",
                battery_capacity=100.0,
                max_charging_power=150.0,
            ),
            Vehicle(
                user_id=user1.id,
                plate="34XYZ789",
                model="Model 3",
                is_active=True,
                current_type="AC",
                connector_type="TYPE_2",
                battery_capacity=75.0,
                max_charging_power=22.0,
            ),
            Vehicle(
                user_id=user2.id,
                plate="35DEF456",
                model="Model X",
                is_active=True,
                current_type="DC",
                connector_type="CHADEMO",
                battery_capacity=90.0,
                max_charging_power=120.0,
            ),
        ]
        db.add_all(vehicles)
        db.commit()
        db.refresh(vehicles[0])
        db.refresh(vehicles[1])
        db.refresh(vehicles[2])

        reservations = [
            Reservation(
                user_id=user1.id,
                vehicle_id=vehicles[0].id,
                charger_id=chargers[1].id,
                start_time=time(10, 0),
                end_time=time(12, 0),
                date=date(2026, 6, 1),
                status="PENDING",
            ),
            Reservation(
                user_id=user1.id,
                vehicle_id=vehicles[1].id,
                charger_id=chargers[0].id,
                start_time=time(14, 0),
                end_time=time(16, 0),
                date=date(2026, 6, 2),
                status="PENDING",
            ),
            Reservation(
                user_id=user2.id,
                vehicle_id=vehicles[2].id,
                charger_id=chargers[1].id,
                start_time=time(9, 0),
                end_time=time(11, 0),
                date=date(2026, 6, 3),
                status="PENDING",
            ),
        ]
        db.add_all(reservations)
        db.commit()
        db.refresh(reservations[0])
        db.refresh(reservations[1])
        db.refresh(reservations[2])

        chargingSession1 = ChargingSession(
            reservation_id=reservations[0].id,
            consuming_power=0.0,
            cost = 0.0,
            start_time=time(10, 0),
            end_time=None,
            status="PENDING",
        )
        chargingSession2 = ChargingSession(
            reservation_id=reservations[1].id,
            consuming_power=0.0,
            cost = 0.0,
            start_time=time(14, 0),
            end_time=None,
            status="PENDING",
        )
        chargingSession3 = ChargingSession(
            reservation_id=reservations[2].id,
            consuming_power=0.0,
            cost = 0.0,
            start_time=time(9, 0),
            end_time=None,
            status="PENDING",
        )
        db.add_all([chargingSession1, chargingSession2, chargingSession3])
        db.commit()
        db.refresh(chargingSession1)
        db.refresh(chargingSession2)
        db.refresh(chargingSession3)

    finally:
        db.close()

        