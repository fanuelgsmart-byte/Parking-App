"""
Shared FastAPI dependencies: JWT auth and camera API-key verification.
"""
from __future__ import annotations

import hashlib
from datetime import datetime, timezone

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.camera_device import CameraDevice
from app.models.employee import Employee

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def _decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


def get_current_employee(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Employee:
    payload = _decode_token(token)
    employee_id: int | None = payload.get("sub")
    if employee_id is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload.")
    emp = db.query(Employee).filter(Employee.id == int(employee_id), Employee.is_active.is_(True)).first()
    if emp is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Employee not found.")
    return emp


def require_manager(emp: Employee = Depends(get_current_employee)) -> Employee:
    if emp.role != "manager":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager access required.")
    return emp


def verify_camera_api_key(
    x_camera_api_key: str = Header(..., alias="X-Camera-Api-Key"),
    db: Session = Depends(get_db),
) -> CameraDevice:
    key_hash = hashlib.sha256(x_camera_api_key.encode()).hexdigest()
    cam = db.query(CameraDevice).filter(
        CameraDevice.api_key_hash == key_hash,
        CameraDevice.is_active.is_(True),
    ).first()
    if cam is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid camera API key.")
    # Update last_seen_at
    cam.last_seen_at = datetime.now(timezone.utc)
    db.commit()
    return cam
