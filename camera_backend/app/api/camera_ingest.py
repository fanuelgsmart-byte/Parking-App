"""
Camera endpoints: pre-registration, QR pairing, config retrieval, and frame ingest.

Flow:
  1. Factory pre-registers camera: POST /camera/pre-register
  2. Manager scans QR and pairs:    POST /camera/pair
  3. Camera boots and gets config:   GET  /camera/config/{camera_uid}
  4. Camera sends detected frames:   POST /camera/frame
     - Entrance camera → creates session, broadcasts session_created
     - Exit camera → finds session, broadcasts vehicle_exiting
"""
from __future__ import annotations

import hashlib
import logging
import secrets
from datetime import datetime, timezone
from pathlib import Path

import cv2
import numpy as np
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.api.deps import require_manager, verify_camera_api_key
from app.config import settings
from app.database import get_db
from app.models.camera_device import CameraDevice
from app.models.employee import Employee
from app.schemas.camera import (
    CameraConfigResponse,
    CameraDeviceOut,
    CameraPairRequest,
    CameraPairResponse,
    CameraPreRegister,
    FrameIngestResult,
)
from app.services import alpr_pipeline, session_service, vehicle_classifier
from app.services.ws_manager import manager as ws_manager

logger = logging.getLogger(__name__)
router = APIRouter(tags=["camera"])


# ---------------------------------------------------------------------------
# 1. Pre-register (factory / admin)
# ---------------------------------------------------------------------------

@router.post("/camera/pre-register", response_model=CameraDeviceOut, status_code=status.HTTP_201_CREATED)
def pre_register_camera(body: CameraPreRegister, db: Session = Depends(get_db)):
    """
    Pre-register a camera before shipping.

    Called during manufacturing — stores the camera_uid and hashed pairing code.
    The camera ships unpaired; a manager will pair it later via QR scan.
    """
    existing = db.query(CameraDevice).filter(CameraDevice.camera_uid == body.camera_uid).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Camera UID already registered.")

    cam = CameraDevice(
        camera_uid=body.camera_uid,
        pairing_code_hash=hashlib.sha256(body.pairing_code.encode()).hexdigest(),
    )
    db.add(cam)
    db.commit()
    db.refresh(cam)
    return cam


# ---------------------------------------------------------------------------
# 2. QR pairing (manager only)
# ---------------------------------------------------------------------------

@router.post("/camera/pair", response_model=CameraPairResponse)
def pair_camera(
    body: CameraPairRequest,
    db: Session = Depends(get_db),
    _mgr: Employee = Depends(require_manager),
):
    """
    Pair a camera to a lot by scanning its QR code.

    Manager provides the camera_uid + pairing_code from the QR sticker,
    chooses the lot, camera type (entrance/exit), and a friendly name.
    Returns the one-time API key that the camera will use at runtime.
    """
    cam = db.query(CameraDevice).filter(CameraDevice.camera_uid == body.camera_uid).first()
    if cam is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camera not found. Is it pre-registered?")

    if cam.is_paired:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Camera is already paired.")

    code_hash = hashlib.sha256(body.pairing_code.encode()).hexdigest()
    if code_hash != cam.pairing_code_hash:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid pairing code.")

    if body.camera_type not in ("entrance", "exit"):
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="camera_type must be 'entrance' or 'exit'.")

    # Generate runtime API key
    raw_key = secrets.token_urlsafe(32)
    cam.api_key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
    cam.lot_id = body.lot_id
    cam.camera_type = body.camera_type
    cam.name = body.name
    cam.is_paired = True
    db.commit()
    db.refresh(cam)

    return CameraPairResponse(
        id=cam.id,
        camera_uid=cam.camera_uid,
        lot_id=cam.lot_id,
        name=cam.name,
        camera_type=cam.camera_type,
        is_paired=cam.is_paired,
        is_active=cam.is_active,
        created_at=cam.created_at,
        api_key=raw_key,
    )


# ---------------------------------------------------------------------------
# 3. Camera config (camera calls on boot)
# ---------------------------------------------------------------------------

@router.get("/camera/config/{camera_uid}", response_model=CameraConfigResponse)
def get_camera_config(camera_uid: str, db: Session = Depends(get_db)):
    """
    Camera calls this on boot to check if it's paired and get its config.

    Returns lot_id, camera_type, and api_key_hash.
    Returns 404 if the camera is not yet paired.
    """
    cam = db.query(CameraDevice).filter(
        CameraDevice.camera_uid == camera_uid,
        CameraDevice.is_paired.is_(True),
        CameraDevice.is_active.is_(True),
    ).first()
    if cam is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camera not paired or not found.")

    return CameraConfigResponse(
        camera_uid=cam.camera_uid,
        lot_id=cam.lot_id,
        camera_type=cam.camera_type,
        api_key_hash=cam.api_key_hash,
    )


# ---------------------------------------------------------------------------
# 4. List cameras for a lot (manager only)
# ---------------------------------------------------------------------------

@router.get("/camera/devices", response_model=list[CameraDeviceOut])
def list_cameras(
    lot_id: str,
    db: Session = Depends(get_db),
    _mgr: Employee = Depends(require_manager),
):
    return (
        db.query(CameraDevice)
        .filter(CameraDevice.lot_id == lot_id)
        .order_by(CameraDevice.created_at.desc())
        .all()
    )


# ---------------------------------------------------------------------------
# 5. Frame ingest (entrance + exit)
# ---------------------------------------------------------------------------

def _save_image(frame_bytes: bytes, plate: str) -> str | None:
    try:
        images_dir = Path(settings.captured_images_dir)
        images_dir.mkdir(parents=True, exist_ok=True)
        ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        safe_plate = plate.replace(" ", "_").replace("/", "-")
        filename = f"{safe_plate}_{ts}.jpg"
        filepath = images_dir / filename
        with open(filepath, "wb") as f:
            f.write(frame_bytes)
        return f"{settings.static_base_url}/images/{filename}"
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed to save captured image: %s", exc)
        return None


@router.post("/camera/frame", response_model=FrameIngestResult)
async def ingest_frame(
    image: UploadFile = File(...),
    cam: CameraDevice = Depends(verify_camera_api_key),
    db: Session = Depends(get_db),
):
    """
    Receive a JPEG frame from a WiFi camera (on-device detection triggered).

    Entrance camera → creates session + broadcasts session_created.
    Exit camera → finds active session + broadcasts vehicle_exiting.
    """
    frame_bytes = await image.read()

    plates = alpr_pipeline.run(frame_bytes)
    if not plates:
        return FrameIngestResult(detected=False, camera_type=cam.camera_type, message="No plate detected.")

    best = max(plates, key=lambda p: p.confidence_score)

    nparr = np.frombuffer(frame_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    vehicle_color = "unknown"
    vehicle_size = "medium"
    if frame is not None:
        vehicle_color = vehicle_classifier.detect_colour(frame, best.bbox)
        vehicle_size = vehicle_classifier.estimate_size(frame, best.bbox)

    image_url = _save_image(frame_bytes, best.license_plate)

    # ---- ENTRANCE CAMERA ----
    if cam.camera_type == "entrance":
        sess = session_service.create_session_from_camera(
            db,
            license_plate=best.license_plate,
            vehicle_size=vehicle_size,
            vehicle_color=vehicle_color,
            lot_id=cam.lot_id,
            image_url=image_url,
        )
        if sess is None:
            return FrameIngestResult(
                detected=True,
                license_plate=best.license_plate,
                confidence=best.confidence,
                vehicle_size=vehicle_size,
                vehicle_color=vehicle_color,
                camera_type=cam.camera_type,
                message="Vehicle already parked or no spot available.",
            )

        rate = session_service.get_active_rate(db, cam.lot_id, vehicle_size)
        await ws_manager.broadcast_session_created(
            cam.lot_id,
            session_id=sess.id,
            license_plate=best.license_plate,
            confidence=best.confidence,
            vehicle_size=vehicle_size,
            vehicle_color=vehicle_color,
            spot_number=sess.spot.spot_number,
            entry_time=sess.entry_time.isoformat(),
            rate_per_hour=rate,
            image_url=image_url,
            timestamp=datetime.now(timezone.utc).isoformat(),
        )
        return FrameIngestResult(
            detected=True,
            license_plate=best.license_plate,
            confidence=best.confidence,
            vehicle_size=vehicle_size,
            vehicle_color=vehicle_color,
            session_id=sess.id,
            camera_type=cam.camera_type,
            message="Session created.",
        )

    # ---- EXIT CAMERA ----
    sess = session_service.find_active_session_by_plate(db, best.license_plate, cam.lot_id)
    if sess is None:
        return FrameIngestResult(
            detected=True,
            license_plate=best.license_plate,
            confidence=best.confidence,
            vehicle_size=vehicle_size,
            vehicle_color=vehicle_color,
            camera_type=cam.camera_type,
            message="No active session found for this plate.",
        )

    # Calculate duration and estimated fee
    now = datetime.now(timezone.utc)
    duration = now - sess.entry_time
    duration_minutes = int(duration.total_seconds() / 60)
    rate = session_service.get_active_rate(db, cam.lot_id, sess.vehicle.size)
    estimated_fee = round(rate * (duration.total_seconds() / 3600), 2)

    await ws_manager.broadcast_vehicle_exiting(
        cam.lot_id,
        session_id=sess.id,
        license_plate=best.license_plate,
        vehicle_size=sess.vehicle.size,
        vehicle_color=sess.vehicle.color,
        spot_number=sess.spot.spot_number,
        entry_time=sess.entry_time.isoformat(),
        duration_minutes=duration_minutes,
        estimated_fee=estimated_fee,
        image_url=image_url,
        timestamp=now.isoformat(),
    )
    return FrameIngestResult(
        detected=True,
        license_plate=best.license_plate,
        confidence=best.confidence,
        vehicle_size=sess.vehicle.size,
        vehicle_color=sess.vehicle.color,
        session_id=sess.id,
        camera_type=cam.camera_type,
        message="Vehicle exiting — employee notified.",
    )
