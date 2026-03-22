from datetime import datetime, timezone

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Vehicle(Base):
    __tablename__ = "vehicles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    license_plate: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    size: Mapped[str] = mapped_column(String(10), nullable=False)   # small / medium / large
    color: Mapped[str] = mapped_column(String(30), nullable=False)
    # URL path to the captured JPEG image (relative to static mount)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    sessions = relationship("ParkingSession", back_populates="vehicle")
