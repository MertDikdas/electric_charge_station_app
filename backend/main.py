from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.infrastructure.database.database import Base, engine
from app.infrastructure.database import tables

from app.presentation.routers.vehicle_router import router as vehicle_router
from app.presentation.routers.station_router import router as station_router
from app.presentation.routers.reservation_router import router as reservation_router
from app.presentation.routers.charging_session_router import router as charging_session_router
from app.presentation.routers.notification_router import router as notification_router
from app.presentation.routers.user_router import router as user_router
from app.presentation.routers.charger_router import router as charger_router
from app.presentation.routers.auth_router import router as auth_router
from app.presentation.routers.coupon_router import router as coupon_router
from app.presentation.routers.payment_router import router as payment_router
from app.presentation.routers.chatbot_router import router as chatbot_router
from app.presentation.routers.company_router import router as company_router
from app.presentation.routers.statistics_router import router as statistics_router
from app.presentation.routers.company_member_router import (
    company_router as company_member_company_router,
)
from app.presentation.routers.company_member_router import router as company_member_router
from app.core.notification_scheduler import (
    start_notification_scheduler,
    stop_notification_scheduler,
)

app = FastAPI(
    title="EV Charging Station Network API",
    description="Backend API for EV charging station management system",
    version="1.0.0"
)

Base.metadata.create_all(bind=engine)

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
app.include_router(notification_router, prefix="/notifications", tags=["Notifications"])
app.include_router(user_router, prefix="/users", tags=["Users"])
app.include_router(charger_router, prefix="/chargers", tags=["Chargers"])
app.include_router(auth_router, prefix="/auth", tags=["Auth"])
app.include_router(coupon_router, prefix="/coupons", tags=["Coupons"])
app.include_router(payment_router, prefix="/payments", tags=["Payments"])
app.include_router(chatbot_router, prefix="/chatbots", tags=["Chatbots"])
app.include_router(company_router, prefix="/admin/companies", tags=["Companies"])
app.include_router(company_member_router, prefix="/admin/company-members", tags=["Company Members"])
app.include_router(company_member_company_router, prefix="/company-members", tags=["Company Members"])
app.include_router(statistics_router, prefix="/statistics", tags=["Statistics"])

@app.on_event("startup")
def startup_event():
    start_notification_scheduler()


@app.on_event("shutdown")
def shutdown_event():
    stop_notification_scheduler()


@app.get("/")
def root():
    return {"message": "EV Charging Station API is running"}
