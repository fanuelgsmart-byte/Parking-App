from datetime import datetime

from pydantic import BaseModel

from app.schemas.vehicle import VehicleOut


class SessionOut(BaseModel):
    id: int
    vehicle: VehicleOut
    spot_id: int
    spot_number: str
    lot_id: str
    entry_time: datetime
    exit_time: datetime | None
    total_fee: float | None
    status: str
    employee_id: int | None
    is_synced: bool

    model_config = {"from_attributes": True}


class CreateSessionRequest(BaseModel):
    license_plate: str
    vehicle_size: str
    vehicle_color: str
    lot_id: str
    employee_id: int | None = None


class CheckoutRequest(BaseModel):
    total_fee: float


class SessionListResponse(BaseModel):
    sessions: list[SessionOut]
