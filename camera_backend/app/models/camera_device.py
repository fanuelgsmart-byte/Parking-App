from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class CameraDevice(Base):
    __tablename__ = "camera_devices"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    # Hardware serial number printed on the QR code sticker
    camera_uid: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    # Nullable until paired — assigned when manager pairs via QR scan
    lot_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("parking_lots.id"), nullable=True, index=True
    )
    name: Mapped[str] = mapped_column(String(120), default="Unnamed Camera")
    # SHA-256 of one-time pairing code (from QR sticker, verified during pairing)
    pairing_code_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    # SHA-256 hex digest of the runtime api_key — generated on successful pairing
    api_key_hash: Mapped[str | None] = mapped_column(String(64), nullable=True, unique=True)
    # "entrance" or "exit" — set by manager during pairing
    camera_type: Mapped[str] = mapped_column(String(10), default="entrance")
    is_paired: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    lot = relationship("ParkingLot", back_populates="cameras")
