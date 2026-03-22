from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class ParkingSpot(Base):
    __tablename__ = "parking_spots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    lot_id: Mapped[str] = mapped_column(String(36), ForeignKey("parking_lots.id"), nullable=False, index=True)
    spot_number: Mapped[str] = mapped_column(String(10), nullable=False)
    size: Mapped[str] = mapped_column(String(10), nullable=False)  # small / medium / large
    status: Mapped[str] = mapped_column(String(20), default="available")  # available / occupied
    row: Mapped[int | None] = mapped_column(Integer, nullable=True)
    col: Mapped[int | None] = mapped_column(Integer, nullable=True)

    lot = relationship("ParkingLot", back_populates="spots")
    sessions = relationship("ParkingSession", back_populates="spot")
