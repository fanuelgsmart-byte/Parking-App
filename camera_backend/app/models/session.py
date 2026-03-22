from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class ParkingSession(Base):
    __tablename__ = "parking_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    vehicle_id: Mapped[int] = mapped_column(Integer, ForeignKey("vehicles.id"), nullable=False, index=True)
    spot_id: Mapped[int] = mapped_column(Integer, ForeignKey("parking_spots.id"), nullable=False)
    lot_id: Mapped[str] = mapped_column(String(36), ForeignKey("parking_lots.id"), nullable=False, index=True)
    entry_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    exit_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    total_fee: Mapped[float | None] = mapped_column(Float, nullable=True)
    # active / flagged_for_checkout / payment_pending / completed
    status: Mapped[str] = mapped_column(String(30), default="active", index=True)
    employee_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("employees.id"), nullable=True, index=True
    )
    is_synced: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    vehicle = relationship("Vehicle", back_populates="sessions")
    spot = relationship("ParkingSpot", back_populates="sessions")
    employee = relationship("Employee", back_populates="sessions")
    payments = relationship("Payment", back_populates="session", cascade="all, delete-orphan")
