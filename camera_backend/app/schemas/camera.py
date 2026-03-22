from datetime import datetime

from pydantic import BaseModel


class CameraDeviceCreate(BaseModel):
    lot_id: str
    name: str


class CameraDeviceOut(BaseModel):
    id: int
    lot_id: str
    name: str
    is_active: bool
    last_seen_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


class CameraDeviceCreated(CameraDeviceOut):
    # Raw API key returned ONCE on creation — not stored in DB
    api_key: str


class FrameIngestResult(BaseModel):
    detected: bool
    license_plate: str | None = None
    confidence: str | None = None
    vehicle_size: str | None = None
    vehicle_color: str | None = None
    session_id: int | None = None
    message: str = "ok"
