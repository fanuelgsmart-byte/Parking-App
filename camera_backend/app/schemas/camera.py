from datetime import datetime

from pydantic import BaseModel


class CameraPreRegister(BaseModel):
    """Factory pre-registers a camera before shipping."""
    camera_uid: str
    pairing_code: str


class CameraPairRequest(BaseModel):
    """Manager pairs a camera by scanning its QR code."""
    camera_uid: str
    pairing_code: str
    lot_id: str
    camera_type: str = "entrance"  # "entrance" or "exit"
    name: str = "Camera"


class CameraPairResponse(BaseModel):
    id: int
    camera_uid: str
    lot_id: str
    name: str
    camera_type: str
    is_paired: bool
    is_active: bool
    created_at: datetime
    # Raw API key returned ONCE — camera must store this
    api_key: str

    model_config = {"from_attributes": True}


class CameraConfigResponse(BaseModel):
    """Returned when a camera checks its config on boot."""
    camera_uid: str
    lot_id: str
    camera_type: str
    api_key_hash: str  # camera can verify its stored key matches


class CameraDeviceOut(BaseModel):
    id: int
    camera_uid: str
    lot_id: str | None
    name: str
    camera_type: str
    is_paired: bool
    is_active: bool
    last_seen_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


class CameraDeviceCreate(BaseModel):
    lot_id: str
    name: str


class CameraDeviceCreated(CameraDeviceOut):
    api_key: str


class FrameIngestResult(BaseModel):
    detected: bool
    license_plate: str | None = None
    confidence: str | None = None
    vehicle_size: str | None = None
    vehicle_color: str | None = None
    session_id: int | None = None
    camera_type: str | None = None
    message: str = "ok"
