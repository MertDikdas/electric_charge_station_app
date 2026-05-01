from sqlalchemy import Column, Date, Float, ForeignKey, Integer, String, Time
from sqlalchemy.orm import relationship
from app.infrastructure.database.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    surname = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    balance = Column(Float, default=0.0)

    vehicles = relationship("Vehicle", back_populates="user")
    reservations = relationship("Reservation", back_populates="user")
