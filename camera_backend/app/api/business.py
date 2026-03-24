"""
Business registration and management endpoints.

Flow:
  1. Owner registers a business: POST /businesses/register
     → creates Business + manager Employee account + returns auth tokens.
  2. Authenticated manager can view/update their business: GET/PUT /businesses/me
"""
from __future__ import annotations

import uuid
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.api.deps import get_current_employee, require_manager
from app.config import settings
from app.database import get_db
from app.models.business import Business
from app.models.employee import Employee
from app.schemas.business import (
    BusinessOut,
    RegisterBusinessRequest,
    RegisterBusinessResponse,
    UpdateBusinessRequest,
)

router = APIRouter(prefix="/businesses", tags=["businesses"])
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _make_token(subject: int, expire_delta: timedelta) -> str:
    from jose import jwt as jose_jwt

    from datetime import datetime, timezone

    expire = datetime.now(timezone.utc) + expire_delta
    return jose_jwt.encode(
        {"sub": str(subject), "exp": expire},
        settings.secret_key,
        algorithm=settings.algorithm,
    )


@router.post("/register", response_model=RegisterBusinessResponse, status_code=status.HTTP_201_CREATED)
def register_business(body: RegisterBusinessRequest, db: Session = Depends(get_db)):
    """
    Register a new business and create the owner's manager account.

    Returns auth tokens so the owner is logged in immediately after registration.
    """
    if body.operation_mode not in ("manual", "camera_gate"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="operation_mode must be 'manual' or 'camera_gate'.",
        )

    # Check for duplicate business email
    if db.query(Business).filter(Business.email == body.business_email).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A business with this email already exists.",
        )

    # Check for duplicate owner email
    if db.query(Employee).filter(Employee.email == body.owner_email).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    business_id = str(uuid.uuid4())
    business = Business(
        id=business_id,
        name=body.business_name,
        owner_name=body.owner_name,
        email=body.business_email,
        phone=body.phone,
        address=body.address,
        operation_mode=body.operation_mode,
    )
    db.add(business)
    db.flush()

    owner = Employee(
        name=body.owner_name,
        email=body.owner_email,
        password_hash=pwd_ctx.hash(body.owner_password),
        role="manager",
        business_id=business_id,
    )
    db.add(owner)
    db.commit()
    db.refresh(business)
    db.refresh(owner)

    access = _make_token(owner.id, timedelta(minutes=settings.access_token_expire_minutes))
    refresh = _make_token(owner.id, timedelta(days=settings.refresh_token_expire_days))

    return RegisterBusinessResponse(
        business=BusinessOut.model_validate(business),
        access_token=access,
        refresh_token=refresh,
    )


@router.get("/me", response_model=BusinessOut)
def get_my_business(
    db: Session = Depends(get_db),
    emp: Employee = Depends(get_current_employee),
):
    """Get the business associated with the current user."""
    if emp.business_id is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No business associated with this account.",
        )
    business = db.query(Business).filter(Business.id == emp.business_id).first()
    if business is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found.")
    return business


@router.put("/me", response_model=BusinessOut)
def update_my_business(
    body: UpdateBusinessRequest,
    db: Session = Depends(get_db),
    mgr: Employee = Depends(require_manager),
):
    """Update the business details. Manager only."""
    if mgr.business_id is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No business associated with this account.",
        )
    business = db.query(Business).filter(Business.id == mgr.business_id).first()
    if business is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found.")

    if body.operation_mode is not None and body.operation_mode not in ("manual", "camera_gate"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="operation_mode must be 'manual' or 'camera_gate'.",
        )

    update_data = body.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(business, field, value)

    db.commit()
    db.refresh(business)
    return business
