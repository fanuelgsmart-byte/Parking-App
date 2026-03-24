from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.deps import get_current_employee
from app.database import get_db
from app.models.employee import Employee
from app.models.lot import ParkingLot
from app.models.spot import ParkingSpot

router = APIRouter(prefix="/lots", tags=["lots"])


class SpotOut(BaseModel):
    id: int
    spot_number: str
    size: str
    status: str
    row: int | None
    col: int | None

    model_config = {"from_attributes": True}


class LotOut(BaseModel):
    id: str
    business_id: str
    name: str
    address: str | None

    model_config = {"from_attributes": True}


@router.get("", response_model=list[LotOut])
def list_lots(db: Session = Depends(get_db), emp: Employee = Depends(get_current_employee)):
    q = db.query(ParkingLot)
    if emp.business_id:
        q = q.filter(ParkingLot.business_id == emp.business_id)
    return q.all()


@router.get("/{lot_id}/spots", response_model=list[SpotOut])
def list_spots(
    lot_id: str,
    db: Session = Depends(get_db),
    _emp: Employee = Depends(get_current_employee),
):
    return db.query(ParkingSpot).filter(ParkingSpot.lot_id == lot_id).order_by(ParkingSpot.spot_number).all()
