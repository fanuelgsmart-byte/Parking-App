from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    actor_id: Mapped[int] = mapped_column(Integer, ForeignKey("employees.id"), nullable=False, index=True)
    action: Mapped[str] = mapped_column(String(50), nullable=False, index=True)  # e.g. lot_created, employee_updated
    entity_type: Mapped[str] = mapped_column(String(50), nullable=False, index=True)  # e.g. lot, employee, spot, camera
    entity_id: Mapped[str] = mapped_column(String(36), nullable=False)
    details: Mapped[str | None] = mapped_column(Text, nullable=True)  # JSON string with extra context
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True
    )

    actor = relationship("Employee")
