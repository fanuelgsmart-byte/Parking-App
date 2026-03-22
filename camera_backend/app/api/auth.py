from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from jose import jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.api.deps import get_current_employee, _decode_token
from app.config import settings
from app.database import get_db
from app.models.employee import Employee
from app.schemas.auth import EmployeeOut, LoginRequest, RefreshRequest, TokenResponse

router = APIRouter(prefix="/auth", tags=["auth"])
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _make_token(subject: int, expire_delta: timedelta) -> str:
    expire = datetime.now(timezone.utc) + expire_delta
    return jwt.encode({"sub": str(subject), "exp": expire}, settings.secret_key, algorithm=settings.algorithm)


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    emp = db.query(Employee).filter(Employee.email == body.email, Employee.is_active.is_(True)).first()
    if emp is None or not pwd_ctx.verify(body.password, emp.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials.")
    access = _make_token(emp.id, timedelta(minutes=settings.access_token_expire_minutes))
    refresh = _make_token(emp.id, timedelta(days=settings.refresh_token_expire_days))
    return TokenResponse(access_token=access, refresh_token=refresh)


@router.post("/refresh", response_model=TokenResponse)
def refresh_token(body: RefreshRequest, db: Session = Depends(get_db)):
    payload = _decode_token(body.refresh_token)
    employee_id = payload.get("sub")
    if employee_id is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token.")
    emp = db.query(Employee).filter(Employee.id == int(employee_id), Employee.is_active.is_(True)).first()
    if emp is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Employee not found.")
    access = _make_token(emp.id, timedelta(minutes=settings.access_token_expire_minutes))
    new_refresh = _make_token(emp.id, timedelta(days=settings.refresh_token_expire_days))
    return TokenResponse(access_token=access, refresh_token=new_refresh)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(_emp: Employee = Depends(get_current_employee)):
    # Stateless JWT — no server-side revocation needed for now.
    return None


@router.get("/me", response_model=EmployeeOut)
def me(emp: Employee = Depends(get_current_employee)):
    return emp
