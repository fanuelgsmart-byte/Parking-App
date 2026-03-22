"""
Superadmin API — system-owner endpoints for managing all parking businesses.
"""
from __future__ import annotations

import hashlib
import json
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from passlib.context import CryptContext
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.deps import require_superadmin
from app.database import get_db
from app.models.audit_log import AuditLog
from app.models.camera_device import CameraDevice
from app.models.employee import Employee
from app.models.lot import ParkingLot
from app.models.payment import Payment
from app.models.session import ParkingSession
from app.models.spot import ParkingSpot
from app.schemas.superadmin import (
    AuditLogEntry,
    CameraOverviewItem,
    CreateEmployeeRequest,
    CreateLotRequest,
    CreateSpotRequest,
    CrossLotOccupancyReport,
    CrossLotRevenueReport,
    DashboardStats,
    EmployeeDetail,
    LotDetail,
    LotOccupancySummary,
    LotRevenueSummary,
    PaginatedAuditLog,
    PreRegisterCameraRequest,
    SpotOut,
    UpdateEmployeeRequest,
    UpdateLotRequest,
    UpdateSpotRequest,
)

router = APIRouter(prefix="/superadmin", tags=["superadmin"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

OPEN_STATUSES = ("active", "flagged_for_checkout", "payment_pending")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _audit(db: Session, actor: Employee, action: str, entity_type: str, entity_id: str, details: dict | None = None):
    entry = AuditLog(
        actor_id=actor.id,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id),
        details=json.dumps(details) if details else None,
    )
    db.add(entry)


# ---------------------------------------------------------------------------
# 1. Dashboard
# ---------------------------------------------------------------------------
@router.get("/dashboard", response_model=DashboardStats)
def dashboard(db: Session = Depends(get_db), _admin: Employee = Depends(require_superadmin)):
    total_lots = db.query(func.count(ParkingLot.id)).scalar() or 0
    total_spots = db.query(func.count(ParkingSpot.id)).scalar() or 0
    occupied_spots = db.query(func.count(ParkingSpot.id)).filter(ParkingSpot.status == "occupied").scalar() or 0
    total_active = (
        db.query(func.count(ParkingSession.id))
        .filter(ParkingSession.status.in_(OPEN_STATUSES))
        .scalar()
        or 0
    )
    total_rev = (
        db.query(func.coalesce(func.sum(Payment.amount), 0.0))
        .filter(Payment.status == "completed")
        .scalar()
    )
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    today_rev = (
        db.query(func.coalesce(func.sum(Payment.amount), 0.0))
        .filter(Payment.status == "completed", Payment.paid_at >= today_start)
        .scalar()
    )
    total_employees = db.query(func.count(Employee.id)).filter(Employee.is_active.is_(True), Employee.role != "superadmin").scalar() or 0
    total_cameras = db.query(func.count(CameraDevice.id)).scalar() or 0
    active_cameras = db.query(func.count(CameraDevice.id)).filter(CameraDevice.is_active.is_(True)).scalar() or 0

    return DashboardStats(
        total_lots=total_lots,
        total_spots=total_spots,
        occupied_spots=occupied_spots,
        total_active_sessions=total_active,
        total_revenue_all_time=float(total_rev or 0),
        total_revenue_today=float(today_rev or 0),
        total_employees=total_employees,
        total_cameras=total_cameras,
        active_cameras=active_cameras,
    )


# ---------------------------------------------------------------------------
# 2. Lot Management
# ---------------------------------------------------------------------------
@router.get("/lots", response_model=list[LotDetail])
def list_lots(db: Session = Depends(get_db), _admin: Employee = Depends(require_superadmin)):
    lots = db.query(ParkingLot).order_by(ParkingLot.name).all()
    result = []
    for lot in lots:
        spot_count = db.query(func.count(ParkingSpot.id)).filter(ParkingSpot.lot_id == lot.id).scalar() or 0
        occupied = db.query(func.count(ParkingSpot.id)).filter(ParkingSpot.lot_id == lot.id, ParkingSpot.status == "occupied").scalar() or 0
        cam_count = db.query(func.count(CameraDevice.id)).filter(CameraDevice.lot_id == lot.id).scalar() or 0
        emp_count = db.query(func.count(Employee.id)).filter(Employee.assigned_lot_id == lot.id, Employee.is_active.is_(True)).scalar() or 0
        result.append(LotDetail(
            id=lot.id,
            name=lot.name,
            address=lot.address,
            timezone=lot.timezone,
            created_at=lot.created_at,
            spot_count=spot_count,
            occupied_count=occupied,
            camera_count=cam_count,
            employee_count=emp_count,
        ))
    return result


@router.post("/lots", response_model=LotDetail, status_code=status.HTTP_201_CREATED)
def create_lot(
    body: CreateLotRequest,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    lot = ParkingLot(id=str(uuid.uuid4()), name=body.name, address=body.address, timezone=body.timezone)
    db.add(lot)
    _audit(db, admin, "lot_created", "lot", lot.id, {"name": body.name})
    db.commit()
    db.refresh(lot)
    return LotDetail(
        id=lot.id, name=lot.name, address=lot.address, timezone=lot.timezone,
        created_at=lot.created_at, spot_count=0, occupied_count=0, camera_count=0, employee_count=0,
    )


@router.put("/lots/{lot_id}", response_model=LotDetail)
def update_lot(
    lot_id: str,
    body: UpdateLotRequest,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    lot = db.query(ParkingLot).filter(ParkingLot.id == lot_id).first()
    if not lot:
        raise HTTPException(status_code=404, detail="Lot not found.")
    changes = {}
    if body.name is not None:
        changes["name"] = body.name
        lot.name = body.name
    if body.address is not None:
        changes["address"] = body.address
        lot.address = body.address
    if body.timezone is not None:
        changes["timezone"] = body.timezone
        lot.timezone = body.timezone
    _audit(db, admin, "lot_updated", "lot", lot_id, changes)
    db.commit()
    db.refresh(lot)
    spot_count = db.query(func.count(ParkingSpot.id)).filter(ParkingSpot.lot_id == lot.id).scalar() or 0
    occupied = db.query(func.count(ParkingSpot.id)).filter(ParkingSpot.lot_id == lot.id, ParkingSpot.status == "occupied").scalar() or 0
    cam_count = db.query(func.count(CameraDevice.id)).filter(CameraDevice.lot_id == lot.id).scalar() or 0
    emp_count = db.query(func.count(Employee.id)).filter(Employee.assigned_lot_id == lot.id, Employee.is_active.is_(True)).scalar() or 0
    return LotDetail(
        id=lot.id, name=lot.name, address=lot.address, timezone=lot.timezone,
        created_at=lot.created_at, spot_count=spot_count, occupied_count=occupied,
        camera_count=cam_count, employee_count=emp_count,
    )


@router.delete("/lots/{lot_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_lot(
    lot_id: str,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    lot = db.query(ParkingLot).filter(ParkingLot.id == lot_id).first()
    if not lot:
        raise HTTPException(status_code=404, detail="Lot not found.")
    _audit(db, admin, "lot_deleted", "lot", lot_id, {"name": lot.name})
    db.delete(lot)
    db.commit()


# ---------------------------------------------------------------------------
# 3. Spot Management
# ---------------------------------------------------------------------------
@router.get("/lots/{lot_id}/spots", response_model=list[SpotOut])
def list_spots(lot_id: str, db: Session = Depends(get_db), _admin: Employee = Depends(require_superadmin)):
    return db.query(ParkingSpot).filter(ParkingSpot.lot_id == lot_id).order_by(ParkingSpot.spot_number).all()


@router.post("/lots/{lot_id}/spots", response_model=SpotOut, status_code=status.HTTP_201_CREATED)
def create_spot(
    lot_id: str,
    body: CreateSpotRequest,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    lot = db.query(ParkingLot).filter(ParkingLot.id == lot_id).first()
    if not lot:
        raise HTTPException(status_code=404, detail="Lot not found.")
    spot = ParkingSpot(lot_id=lot_id, spot_number=body.spot_number, size=body.size, row=body.row, col=body.col)
    db.add(spot)
    _audit(db, admin, "spot_created", "spot", f"{lot_id}/{body.spot_number}", {"size": body.size})
    db.commit()
    db.refresh(spot)
    return spot


@router.put("/lots/{lot_id}/spots/{spot_id}", response_model=SpotOut)
def update_spot(
    lot_id: str,
    spot_id: int,
    body: UpdateSpotRequest,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    spot = db.query(ParkingSpot).filter(ParkingSpot.id == spot_id, ParkingSpot.lot_id == lot_id).first()
    if not spot:
        raise HTTPException(status_code=404, detail="Spot not found.")
    changes = {}
    if body.spot_number is not None:
        changes["spot_number"] = body.spot_number
        spot.spot_number = body.spot_number
    if body.size is not None:
        changes["size"] = body.size
        spot.size = body.size
    if body.row is not None:
        changes["row"] = body.row
        spot.row = body.row
    if body.col is not None:
        changes["col"] = body.col
        spot.col = body.col
    _audit(db, admin, "spot_updated", "spot", str(spot_id), changes)
    db.commit()
    db.refresh(spot)
    return spot


@router.delete("/lots/{lot_id}/spots/{spot_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_spot(
    lot_id: str,
    spot_id: int,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    spot = db.query(ParkingSpot).filter(ParkingSpot.id == spot_id, ParkingSpot.lot_id == lot_id).first()
    if not spot:
        raise HTTPException(status_code=404, detail="Spot not found.")
    _audit(db, admin, "spot_deleted", "spot", str(spot_id), {"spot_number": spot.spot_number})
    db.delete(spot)
    db.commit()


# ---------------------------------------------------------------------------
# 4. Cross-lot Reports
# ---------------------------------------------------------------------------
@router.get("/reports/revenue", response_model=CrossLotRevenueReport)
def cross_lot_revenue(
    start_date: datetime,
    end_date: datetime,
    db: Session = Depends(get_db),
    _admin: Employee = Depends(require_superadmin),
):
    rows = (
        db.query(
            ParkingLot.id,
            ParkingLot.name,
            func.coalesce(func.sum(Payment.amount), 0.0).label("revenue"),
            func.count(ParkingSession.id).label("sessions"),
        )
        .outerjoin(ParkingSession, ParkingSession.lot_id == ParkingLot.id)
        .outerjoin(Payment, Payment.session_id == ParkingSession.id)
        .filter(
            (ParkingSession.entry_time >= start_date) | (ParkingSession.id.is_(None)),
            (ParkingSession.entry_time <= end_date) | (ParkingSession.id.is_(None)),
            (Payment.status == "completed") | (Payment.id.is_(None)),
        )
        .group_by(ParkingLot.id)
        .all()
    )
    per_lot = [
        LotRevenueSummary(lot_id=r.id, lot_name=r.name, total_revenue=float(r.revenue), total_sessions=r.sessions)
        for r in rows
    ]
    return CrossLotRevenueReport(
        start_date=start_date,
        end_date=end_date,
        grand_total_revenue=sum(l.total_revenue for l in per_lot),
        grand_total_sessions=sum(l.total_sessions for l in per_lot),
        per_lot=per_lot,
    )


@router.get("/reports/occupancy", response_model=CrossLotOccupancyReport)
def cross_lot_occupancy(db: Session = Depends(get_db), _admin: Employee = Depends(require_superadmin)):
    lots = db.query(ParkingLot).all()
    per_lot = []
    total_spots = 0
    total_occupied = 0
    for lot in lots:
        t = db.query(func.count(ParkingSpot.id)).filter(ParkingSpot.lot_id == lot.id).scalar() or 0
        o = db.query(func.count(ParkingSpot.id)).filter(ParkingSpot.lot_id == lot.id, ParkingSpot.status == "occupied").scalar() or 0
        rate = (o / t * 100) if t > 0 else 0.0
        per_lot.append(LotOccupancySummary(lot_id=lot.id, lot_name=lot.name, total_spots=t, occupied_spots=o, occupancy_rate=round(rate, 1)))
        total_spots += t
        total_occupied += o

    overall = (total_occupied / total_spots * 100) if total_spots > 0 else 0.0
    return CrossLotOccupancyReport(
        total_spots=total_spots,
        total_occupied=total_occupied,
        overall_rate=round(overall, 1),
        per_lot=per_lot,
    )


# ---------------------------------------------------------------------------
# 5. Employee Management
# ---------------------------------------------------------------------------
@router.get("/employees", response_model=list[EmployeeDetail])
def list_employees(
    lot_id: str | None = Query(None),
    db: Session = Depends(get_db),
    _admin: Employee = Depends(require_superadmin),
):
    q = db.query(Employee).filter(Employee.role != "superadmin")
    if lot_id:
        q = q.filter(Employee.assigned_lot_id == lot_id)
    employees = q.order_by(Employee.name).all()
    result = []
    for emp in employees:
        lot_name = None
        if emp.assigned_lot_id:
            lot = db.query(ParkingLot).filter(ParkingLot.id == emp.assigned_lot_id).first()
            lot_name = lot.name if lot else None
        result.append(EmployeeDetail(
            id=emp.id, remote_id=emp.remote_id, name=emp.name, email=emp.email,
            role=emp.role, assigned_lot_id=emp.assigned_lot_id,
            assigned_lot_name=lot_name, is_active=emp.is_active, created_at=emp.created_at,
        ))
    return result


@router.post("/employees", response_model=EmployeeDetail, status_code=status.HTTP_201_CREATED)
def create_employee(
    body: CreateEmployeeRequest,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    existing = db.query(Employee).filter(Employee.email == body.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already in use.")
    emp = Employee(
        name=body.name,
        email=body.email,
        password_hash=pwd_context.hash(body.password),
        role=body.role,
        assigned_lot_id=body.assigned_lot_id,
    )
    db.add(emp)
    _audit(db, admin, "employee_created", "employee", str(emp.id), {"name": body.name, "role": body.role})
    db.commit()
    db.refresh(emp)
    lot_name = None
    if emp.assigned_lot_id:
        lot = db.query(ParkingLot).filter(ParkingLot.id == emp.assigned_lot_id).first()
        lot_name = lot.name if lot else None
    return EmployeeDetail(
        id=emp.id, remote_id=emp.remote_id, name=emp.name, email=emp.email,
        role=emp.role, assigned_lot_id=emp.assigned_lot_id,
        assigned_lot_name=lot_name, is_active=emp.is_active, created_at=emp.created_at,
    )


@router.put("/employees/{employee_id}", response_model=EmployeeDetail)
def update_employee(
    employee_id: int,
    body: UpdateEmployeeRequest,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found.")
    if emp.role == "superadmin":
        raise HTTPException(status_code=403, detail="Cannot modify superadmin accounts.")
    changes = {}
    if body.name is not None:
        changes["name"] = body.name
        emp.name = body.name
    if body.email is not None:
        dup = db.query(Employee).filter(Employee.email == body.email, Employee.id != employee_id).first()
        if dup:
            raise HTTPException(status_code=409, detail="Email already in use.")
        changes["email"] = body.email
        emp.email = body.email
    if body.role is not None:
        changes["role"] = body.role
        emp.role = body.role
    if body.assigned_lot_id is not None:
        changes["assigned_lot_id"] = body.assigned_lot_id
        emp.assigned_lot_id = body.assigned_lot_id
    if body.is_active is not None:
        changes["is_active"] = body.is_active
        emp.is_active = body.is_active
    _audit(db, admin, "employee_updated", "employee", str(employee_id), changes)
    db.commit()
    db.refresh(emp)
    lot_name = None
    if emp.assigned_lot_id:
        lot = db.query(ParkingLot).filter(ParkingLot.id == emp.assigned_lot_id).first()
        lot_name = lot.name if lot else None
    return EmployeeDetail(
        id=emp.id, remote_id=emp.remote_id, name=emp.name, email=emp.email,
        role=emp.role, assigned_lot_id=emp.assigned_lot_id,
        assigned_lot_name=lot_name, is_active=emp.is_active, created_at=emp.created_at,
    )


@router.delete("/employees/{employee_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_employee(
    employee_id: int,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found.")
    if emp.role == "superadmin":
        raise HTTPException(status_code=403, detail="Cannot deactivate superadmin accounts.")
    emp.is_active = False
    _audit(db, admin, "employee_deactivated", "employee", str(employee_id), {"name": emp.name})
    db.commit()


# ---------------------------------------------------------------------------
# 6. Camera Overview
# ---------------------------------------------------------------------------
@router.get("/cameras", response_model=list[CameraOverviewItem])
def list_cameras(db: Session = Depends(get_db), _admin: Employee = Depends(require_superadmin)):
    cams = db.query(CameraDevice).order_by(CameraDevice.created_at.desc()).all()
    result = []
    for cam in cams:
        lot_name = None
        if cam.lot_id:
            lot = db.query(ParkingLot).filter(ParkingLot.id == cam.lot_id).first()
            lot_name = lot.name if lot else None
        result.append(CameraOverviewItem(
            id=cam.id, camera_uid=cam.camera_uid, lot_id=cam.lot_id,
            lot_name=lot_name, name=cam.name, camera_type=cam.camera_type,
            is_paired=cam.is_paired, is_active=cam.is_active,
            last_seen_at=cam.last_seen_at, created_at=cam.created_at,
        ))
    return result


@router.post("/cameras/pre-register", response_model=CameraOverviewItem, status_code=status.HTTP_201_CREATED)
def pre_register_camera(
    body: PreRegisterCameraRequest,
    db: Session = Depends(get_db),
    admin: Employee = Depends(require_superadmin),
):
    existing = db.query(CameraDevice).filter(CameraDevice.camera_uid == body.camera_uid).first()
    if existing:
        raise HTTPException(status_code=409, detail="Camera UID already registered.")
    cam = CameraDevice(
        camera_uid=body.camera_uid,
        name=f"Camera {body.camera_uid[:8]}",
        pairing_code_hash=hashlib.sha256(body.pairing_code.encode()).hexdigest(),
        camera_type="entrance",
    )
    db.add(cam)
    _audit(db, admin, "camera_pre_registered", "camera", body.camera_uid)
    db.commit()
    db.refresh(cam)
    return CameraOverviewItem(
        id=cam.id, camera_uid=cam.camera_uid, lot_id=cam.lot_id,
        lot_name=None, name=cam.name, camera_type=cam.camera_type,
        is_paired=cam.is_paired, is_active=cam.is_active,
        last_seen_at=cam.last_seen_at, created_at=cam.created_at,
    )


# ---------------------------------------------------------------------------
# 7. Audit Log
# ---------------------------------------------------------------------------
@router.get("/audit-log", response_model=PaginatedAuditLog)
def get_audit_log(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    action: str | None = Query(None),
    entity_type: str | None = Query(None),
    db: Session = Depends(get_db),
    _admin: Employee = Depends(require_superadmin),
):
    q = db.query(AuditLog)
    if action:
        q = q.filter(AuditLog.action == action)
    if entity_type:
        q = q.filter(AuditLog.entity_type == entity_type)
    total = q.count()
    entries = q.order_by(AuditLog.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    items = []
    for e in entries:
        actor = db.query(Employee).filter(Employee.id == e.actor_id).first()
        items.append(AuditLogEntry(
            id=e.id, actor_id=e.actor_id, actor_name=actor.name if actor else None,
            action=e.action, entity_type=e.entity_type, entity_id=e.entity_id,
            details=e.details, created_at=e.created_at,
        ))
    return PaginatedAuditLog(total=total, page=page, page_size=page_size, entries=items)
