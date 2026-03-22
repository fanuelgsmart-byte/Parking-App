from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.deps import get_current_employee
from app.database import get_db
from app.models.employee import Employee
from app.models.payment import Payment
from app.models.session import ParkingSession

router = APIRouter(prefix="/reports", tags=["reports"])


class RevenueReport(BaseModel):
    lot_id: str
    start_date: datetime
    end_date: datetime
    total_revenue: float
    total_sessions: int


class OccupancyReport(BaseModel):
    lot_id: str
    total_spots: int
    occupied_spots: int
    occupancy_rate: float


class EmployeeReport(BaseModel):
    employee_id: int
    name: str
    total_sessions: int
    total_revenue: float


@router.get("/revenue", response_model=RevenueReport)
def revenue_report(
    lot_id: str,
    start_date: datetime,
    end_date: datetime,
    db: Session = Depends(get_db),
    _emp: Employee = Depends(get_current_employee),
):
    result = (
        db.query(
            func.coalesce(func.sum(Payment.amount), 0.0).label("total"),
            func.count(ParkingSession.id).label("count"),
        )
        .join(ParkingSession, ParkingSession.id == Payment.session_id)
        .filter(
            ParkingSession.lot_id == lot_id,
            ParkingSession.entry_time >= start_date,
            ParkingSession.entry_time <= end_date,
            Payment.status == "completed",
        )
        .first()
    )
    return RevenueReport(
        lot_id=lot_id,
        start_date=start_date,
        end_date=end_date,
        total_revenue=float(result.total or 0),
        total_sessions=int(result.count or 0),
    )


@router.get("/occupancy", response_model=OccupancyReport)
def occupancy_report(
    lot_id: str,
    db: Session = Depends(get_db),
    _emp: Employee = Depends(get_current_employee),
):
    from app.models.spot import ParkingSpot

    total = db.query(func.count(ParkingSpot.id)).filter(ParkingSpot.lot_id == lot_id).scalar() or 0
    occupied = (
        db.query(func.count(ParkingSpot.id))
        .filter(ParkingSpot.lot_id == lot_id, ParkingSpot.status == "occupied")
        .scalar()
        or 0
    )
    rate = (occupied / total * 100) if total > 0 else 0.0
    return OccupancyReport(lot_id=lot_id, total_spots=total, occupied_spots=occupied, occupancy_rate=rate)


@router.get("/employees", response_model=list[EmployeeReport])
def employee_report(
    lot_id: str,
    db: Session = Depends(get_db),
    _emp: Employee = Depends(get_current_employee),
):
    rows = (
        db.query(
            Employee.id,
            Employee.name,
            func.count(ParkingSession.id).label("sessions"),
            func.coalesce(func.sum(Payment.amount), 0.0).label("revenue"),
        )
        .join(ParkingSession, ParkingSession.employee_id == Employee.id, isouter=True)
        .join(Payment, Payment.session_id == ParkingSession.id, isouter=True)
        .filter(Employee.assigned_lot_id == lot_id)
        .group_by(Employee.id)
        .all()
    )
    return [
        EmployeeReport(
            employee_id=r.id,
            name=r.name,
            total_sessions=r.sessions,
            total_revenue=float(r.revenue),
        )
        for r in rows
    ]
