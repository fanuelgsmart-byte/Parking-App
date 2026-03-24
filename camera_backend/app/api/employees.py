from fastapi import APIRouter, Depends, HTTPException, status
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from app.api.deps import get_current_employee, require_manager
from app.database import get_db
from app.models.employee import Employee
from app.schemas.auth import EmployeeOut

router = APIRouter(prefix="/employees", tags=["employees"])
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


class CreateEmployeeRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str = "employee"
    assigned_lot_id: str | None = None


@router.get("", response_model=list[EmployeeOut])
def list_employees(
    db: Session = Depends(get_db),
    mgr: Employee = Depends(require_manager),
):
    q = db.query(Employee).filter(Employee.is_active.is_(True))
    if mgr.business_id:
        q = q.filter(Employee.business_id == mgr.business_id)
    return q.all()


@router.post("", response_model=EmployeeOut, status_code=status.HTTP_201_CREATED)
def create_employee(
    body: CreateEmployeeRequest,
    db: Session = Depends(get_db),
    mgr: Employee = Depends(require_manager),
):
    if db.query(Employee).filter(Employee.email == body.email).first():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered.")
    emp = Employee(
        name=body.name,
        email=body.email,
        password_hash=pwd_ctx.hash(body.password),
        role=body.role,
        business_id=mgr.business_id,
        assigned_lot_id=body.assigned_lot_id,
    )
    db.add(emp)
    db.commit()
    db.refresh(emp)
    return emp
