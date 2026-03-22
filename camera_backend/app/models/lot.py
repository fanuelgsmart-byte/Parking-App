from datetime import datetime, timezone

from sqlalchemy import DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class ParkingLot(Base):
    __tablename__ = "parking_lots"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    timezone: Mapped[str] = mapped_column(String(64), default="UTC")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    spots = relationship("ParkingSpot", back_populates="lot", cascade="all, delete-orphan")
    cameras = relationship("CameraDevice", back_populates="lot", cascade="all, delete-orphan")
    employees = relationship("Employee", back_populates="lot")
    rates = relationship("ParkingRate", back_populates="lot", cascade="all, delete-orphan")
