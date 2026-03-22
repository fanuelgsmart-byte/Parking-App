"""
WebSocket endpoint consumed by the Flutter CameraWebSocketService.

Protocol (matches existing Flutter implementation):

Client → Server:
  {"type": "auth",      "payload": {"token": "<jwt>"}}
  {"type": "ping"}

Server → Client:
  {"type": "auth_success"}
  {"type": "auth_failed"}
  {"type": "pong"}
  {"type": "plate_detected",  "payload": {license_plate, confidence, timestamp}}
  {"type": "session_created", "payload": {session_id, license_plate, confidence,
                                          vehicle_size, vehicle_color, spot_number,
                                          entry_time, rate_per_hour, image_url, timestamp}}
"""
from __future__ import annotations

import json
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import SessionLocal
from app.models.employee import Employee
from app.services.ws_manager import manager

logger = logging.getLogger(__name__)
router = APIRouter()


def _verify_token(token: str, db: Session) -> Employee | None:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        employee_id = payload.get("sub")
        if employee_id is None:
            return None
        return db.query(Employee).filter(
            Employee.id == int(employee_id), Employee.is_active.is_(True)
        ).first()
    except JWTError:
        return None


@router.websocket("/ws/camera/{lot_id}")
async def camera_websocket(lot_id: str, ws: WebSocket):
    await manager.connect(lot_id, ws)
    db = SessionLocal()
    authenticated = False

    try:
        while True:
            raw = await ws.receive_text()
            try:
                msg = json.loads(raw)
            except json.JSONDecodeError:
                continue

            msg_type = msg.get("type")

            if msg_type == "auth":
                token = (msg.get("payload") or {}).get("token", "")
                emp = _verify_token(token, db)
                if emp is not None:
                    authenticated = True
                    await ws.send_text(json.dumps({"type": "auth_success"}))
                else:
                    await ws.send_text(json.dumps({"type": "auth_failed"}))
                continue

            if not authenticated:
                await ws.send_text(json.dumps({"type": "auth_failed"}))
                continue

            if msg_type == "ping":
                await ws.send_text(json.dumps({"type": "pong"}))

    except WebSocketDisconnect:
        logger.info("WS disconnected: lot=%s", lot_id)
    finally:
        manager.disconnect(lot_id, ws)
        db.close()
