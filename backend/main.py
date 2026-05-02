from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.infrastructure.database.database import Base, engine
from app.infrastructure.database import tables

from app.infrastructure.database.database import Base, engine
from app.infrastructure.database import tables

from app.presentation.routers.vehicle_router import router as vehicle_router
from app.presentation.routers.station_router import router as station_router
from app.presentation.routers.reservation_router import router as reservation_router
from app.presentation.routers.charging_session_router import router as charging_session_router
from app.presentation.routers.user_router import router as user_router
from app.presentation.routers.charger_router import router as charger_router

from app.infrastructure.database.seed_data import seed_data

#seed_data()

app = FastAPI(
    title="EV Charging Station Network API",
    description="Backend API for EV charging station management system",
    version="1.0.0"
)

Base.metadata.create_all(bind=engine)

print("Database tables created successfully.")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(vehicle_router, prefix="/vehicles", tags=["Vehicles"])
app.include_router(station_router, prefix="/stations", tags=["Stations"])
app.include_router(reservation_router, prefix="/reservations", tags=["Reservations"])
app.include_router(charging_session_router, prefix="/charging-sessions", tags=["Charging Sessions"])
app.include_router(user_router, prefix="/users", tags=["Users"])
app.include_router(charger_router, prefix="/chargers", tags=["Chargers"])


@app.get("/")
def root():
    return {"message": "EV Charging Station API is running"}
