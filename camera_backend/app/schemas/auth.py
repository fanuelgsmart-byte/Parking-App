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
    assigned_lot_id: str | None
    is_active: bool

    model_config = {"from_attributes": True}
