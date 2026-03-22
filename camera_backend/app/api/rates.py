from datetime import datetime, timezone

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.deps import get_current_employee, require_manager
from app.database import get_db
from app.models.employee import Employee
from app.models.rate import ParkingRate

router = APIRouter(prefix="/rates", tags=["rates"])


class RateOut(BaseModel):
    id: int
    lot_id: str
    vehicle_size: str
    rate_per_hour: float
    is_active: bool
    effective_from: datetime
    effective_to: datetime | None

    model_config = {"from_attributes": True}


class UpsertRateRequest(BaseModel):
    lot_id: str
    vehicle_size: str
    rate_per_hour: float


@router.get("", response_model=list[RateOut])
def list_rates(
    lot_id: str | None = None,
    db: Session = Depends(get_db),
    _emp: Employee = Depends(get_current_employee),
):
    q = db.query(ParkingRate).filter(ParkingRate.is_active.is_(True))
    if lot_id:
        q = q.filter(ParkingRate.lot_id == lot_id)
    return q.all()


@router.post("", response_model=RateOut, status_code=status.HTTP_201_CREATED)
def upsert_rate(
    body: UpsertRateRequest,
    db: Session = Depends(get_db),
    _mgr: Employee = Depends(require_manager),
):
    # Deactivate existing active rate for same lot + size
    db.query(ParkingRate).filter(
        ParkingRate.lot_id == body.lot_id,
        ParkingRate.vehicle_size == body.vehicle_size,
        ParkingRate.is_active.is_(True),
    ).update({"is_active": False})

    rate = ParkingRate(
        lot_id=body.lot_id,
        vehicle_size=body.vehicle_size,
        rate_per_hour=body.rate_per_hour,
        is_active=True,
        effective_from=datetime.now(timezone.utc),
    )
    db.add(rate)
    db.commit()
    db.refresh(rate)
    return rate
