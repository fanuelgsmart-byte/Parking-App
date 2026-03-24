from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class EmployeeOut(BaseModel):
    id: int
    remote_id: str | None
    name: str
    email: str
    role: str
    business_id: str | None
    assigned_lot_id: str | None
    is_active: bool

    model_config = {"from_attributes": True}


class UserInfo(BaseModel):
    id: str
    name: str
    email: str
    role: str
    business_id: str | None
    assigned_lot_id: str | None
    operation_mode: str | None

    model_config = {"from_attributes": True}


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserInfo
    business_id: str | None = None
    operation_mode: str | None = None
