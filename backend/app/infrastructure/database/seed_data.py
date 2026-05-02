from app.infrastructure.database.database import SessionLocal
from app.infrastructure.database.tables import Station, Charger, User, Vehicle

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
        db.add_all(user1)
        db.add_all(user2)
        db.commit()
        db.refresh(user1)
        db.refresh(user2)

        vehicles = [
            Vehicle(
                "user_id": user1.id,
                "plate": "34ABC123",
                "model": "Model S",
                "is_active": True,
                "current_type": "DC",
                "connector_type": "CCS2",
                "battery_capacity": 100.0,
                "max_charging_power": 150.0,
            ),
            Vehicle(
                "user_id": user1.id,
                "plate": "34XYZ789",
                "model": "Model 3",
                "is_active": True,
                "current_type": "AC",
                "connector_type": "TYPE_2",
                "battery_capacity": 75.0,
                "max_charging_power": 22.0,
            ),
            Vehicle(
                "user_id": user2.id,
                "plate": "35DEF456",
                "model": "Model X",
                "is_active": True,
                "current_type": "DC",
                "connector_type": "CHADEMO",
                "battery_capacity": 90.0,
                "max_charging_power": 120.0,
            ),
        ]
        db.add_all(vehicles)
        db.commit()
        db.refresh(vehicles[0])
        db.refresh(vehicles[1])
        db.refresh(vehicles[2])
        