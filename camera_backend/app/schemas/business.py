from datetime import datetime

from pydantic import BaseModel, EmailStr


class BusinessOut(BaseModel):
    id: str
    name: str
    owner_name: str
    email: str
    phone: str | None
    address: str | None
    operation_mode: str
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class RegisterBusinessRequest(BaseModel):
    """Register a new business and create the owner (manager) account."""

    # Business fields
    business_name: str
    owner_name: str
    business_email: EmailStr
    phone: str | None = None
    address: str | None = None
    operation_mode: str = "manual"  # "manual" or "camera_gate"

    # Owner account credentials
    owner_email: EmailStr
    owner_password: str


class UpdateBusinessRequest(BaseModel):
    name: str | None = None
    owner_name: str | None = None
    email: EmailStr | None = None
    phone: str | None = None
    address: str | None = None
    operation_mode: str | None = None


class RegisterBusinessResponse(BaseModel):
    business: BusinessOut
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
