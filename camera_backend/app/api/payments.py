import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.deps import get_current_employee
from app.database import get_db
from app.models.employee import Employee
from app.models.payment import Payment
from app.models.session import ParkingSession

router = APIRouter(prefix="/payments", tags=["payments"])


class PaymentRequest(BaseModel):
    session_id: int
    amount: float
    method: str  # cash / qr
    transaction_ref: str | None = None


class PaymentOut(BaseModel):
    id: int
    session_id: int
    amount: float
    method: str
    status: str
    transaction_ref: str | None
    paid_at: datetime | None

    model_config = {"from_attributes": True}


class QrSessionOut(BaseModel):
    qr_token: str
    amount: float
    session_id: int


@router.post("", response_model=PaymentOut, status_code=status.HTTP_201_CREATED)
def record_payment(
    body: PaymentRequest,
    db: Session = Depends(get_db),
    _emp: Employee = Depends(get_current_employee),
):
    sess = db.query(ParkingSession).filter(ParkingSession.id == body.session_id).first()
    if sess is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

    now = datetime.now(timezone.utc)
    payment = Payment(
        session_id=body.session_id,
        amount=body.amount,
        method=body.method,
        status="completed",
        transaction_ref=body.transaction_ref,
        paid_at=now,
    )
    db.add(payment)
    sess.status = "completed"
    sess.total_fee = body.amount
    sess.exit_time = now
    db.commit()
    db.refresh(payment)
    return payment


@router.post("/qr", response_model=QrSessionOut)
def get_qr_session(
    session_id: int,
    db: Session = Depends(get_db),
    _emp: Employee = Depends(get_current_employee),
):
    sess = db.query(ParkingSession).filter(ParkingSession.id == session_id).first()
    if sess is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    # Generate a short-lived QR token (in production this would call a payment provider)
    qr_token = secrets.token_urlsafe(16)
    return QrSessionOut(qr_token=qr_token, amount=sess.total_fee or 0.0, session_id=session_id)
