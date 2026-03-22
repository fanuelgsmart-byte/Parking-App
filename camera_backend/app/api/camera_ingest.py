"""
Camera frame ingestion endpoint.

WiFi cameras POST a JPEG image here. The endpoint runs the full AI pipeline
and — if a plate is detected — creates a session and broadcasts a
`session_created` WebSocket event to connected Flutter clients.
"""
from __future__ import annotations

import hashlib
import logging
import os
from datetime import datetime, timezone
from pathlib import Path

import cv2
import numpy as np

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.api.deps import verify_camera_api_key
from app.config import settings
from app.database import get_db
from app.models.camera_device import CameraDevice
from app.schemas.camera import CameraDeviceCreate, CameraDeviceCreated, FrameIngestResult
from app.services import alpr_pipeline, vehicle_classifier, session_service
from app.services.ws_manager import manager as ws_manager

logger = logging.getLogger(__name__)
router = APIRouter(tags=["camera"])


# ---------------------------------------------------------------------------
# Camera device registration (manager only)
# ---------------------------------------------------------------------------

@router.post("/camera/devices", response_model=CameraDeviceCreated, status_code=status.HTTP_201_CREATED)
def register_camera(
    body: CameraDeviceCreate,
    db: Session = Depends(get_db),
):
    """Register a new camera device and return its one-time API key."""
    import secrets
    import hashlib
    from app.models.camera_device import CameraDevice

    raw_key = secrets.token_urlsafe(32)
    key_hash = hashlib.sha256(raw_key.encode()).hexdigest()

    cam = CameraDevice(lot_id=body.lot_id, name=body.name, api_key_hash=key_hash)
    db.add(cam)
    db.commit()
    db.refresh(cam)

    return CameraDeviceCreated(
        id=cam.id,
        lot_id=cam.lot_id,
        name=cam.name,
        is_active=cam.is_active,
        last_seen_at=cam.last_seen_at,
        created_at=cam.created_at,
        api_key=raw_key,
    )


# ---------------------------------------------------------------------------
# Frame ingest
# ---------------------------------------------------------------------------

def _save_image(frame_bytes: bytes, plate: str) -> str | None:
    """Save the captured frame and return its URL path."""
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
    Receive a JPEG frame from a WiFi camera.

    Runs ALPR + colour/size classification, creates a session if a new
    vehicle is detected, and broadcasts `session_created` to Flutter clients.
    """
    frame_bytes = await image.read()

    plates = alpr_pipeline.run(frame_bytes)
    if not plates:
        return FrameIngestResult(detected=False, message="No plate detected.")

    # Process the highest-confidence detection
    best = max(plates, key=lambda p: p.confidence_score)

    # Decode frame for colour/size analysis
    nparr = np.frombuffer(frame_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    vehicle_color = "unknown"
    vehicle_size = "medium"
    if frame is not None:
        vehicle_color = vehicle_classifier.detect_colour(frame, best.bbox)
        vehicle_size = vehicle_classifier.estimate_size(frame, best.bbox)

    image_url = _save_image(frame_bytes, best.license_plate)

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
            message="Vehicle already parked or no spot available.",
        )

    rate = session_service.get_active_rate(db, cam.lot_id, vehicle_size)

    # Broadcast session_created to all Flutter clients in this lot
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
        message="Session created.",
    )
