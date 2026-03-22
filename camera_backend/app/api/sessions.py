from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_employee
from app.database import get_db
from app.models.employee import Employee
from app.models.session import ParkingSession
from app.models.spot import ParkingSpot
from app.models.vehicle import Vehicle
from app.schemas.session import (
    CheckoutRequest,
    CreateSessionRequest,
    SessionListResponse,
    SessionOut,
)
from app.services import session_service

router = APIRouter(prefix="/sessions", tags=["sessions"])

_OPEN = ("active", "flagged_for_checkout", "payment_pending")


def _to_out(s: ParkingSession, db: Session) -> SessionOut:
    vehicle = db.query(Vehicle).filter(Vehicle.id == s.vehicle_id).first()
    spot = db.query(ParkingSpot).filter(ParkingSpot.id == s.spot_id).first()
    return SessionOut(
        id=s.id,
        vehicle=vehicle,
        spot_id=s.spot_id,
        spot_number=spot.spot_number if spot else "",
        lot_id=s.lot_id,
        entry_time=s.entry_time,
        exit_time=s.exit_time,
        total_fee=s.total_fee,
        status=s.status,
        employee_id=s.employee_id,
        is_synced=s.is_synced,
    )


@router.get("/active", response_model=SessionListResponse)
def get_active_sessions(
    lot_id: str,
    db: Session = Depends(get_db),
    _emp: Employee = Depends(get_current_employee),
):
    rows = (
        db.query(ParkingSession)
        .filter(ParkingSession.lot_id == lot_id, ParkingSession.status.in_(_OPEN))
        .order_by(ParkingSession.entry_time.desc())
        .all()
    )
    return SessionListResponse(sessions=[_to_out(r, db) for r in rows])


@router.post("", response_model=SessionOut, status_code=status.HTTP_201_CREATED)
def create_session(
    body: CreateSessionRequest,
    db: Session = Depends(get_db),
    emp: Employee = Depends(get_current_employee),
):
    sess = session_service.create_session_from_camera(
        db,
        license_plate=body.license_plate,
        vehicle_size=body.vehicle_size,
        vehicle_color=body.vehicle_color,
        lot_id=body.lot_id,
    )
    if sess is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Vehicle already parked or no spot available.",
        )
    return _to_out(sess, db)


@router.post("/{session_id}/checkout", response_model=SessionOut)
def checkout_session(
    session_id: int,
    body: CheckoutRequest,
    db: Session = Depends(get_db),
    _emp: Employee = Depends(get_current_employee),
):
    sess = db.query(ParkingSession).filter(ParkingSession.id == session_id).first()
    if sess is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    if sess.status not in ("active", "flagged_for_checkout", "payment_pending"):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Session already completed.")

    from datetime import datetime, timezone

    sess.status = "completed"
    sess.exit_time = datetime.now(timezone.utc)
    sess.total_fee = body.total_fee
    sess.is_synced = False

    spot = db.query(ParkingSpot).filter(ParkingSpot.id == sess.spot_id).first()
    if spot:
        spot.status = "available"

    db.commit()
    db.refresh(sess)
    return _to_out(sess, db)
