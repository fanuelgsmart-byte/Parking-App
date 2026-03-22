"""
Per-lot WebSocket connection manager.

Keeps a registry of connected Flutter clients and broadcasts JSON messages to
all clients in a given lot room.
"""
from __future__ import annotations

import json
import logging
from collections import defaultdict

from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    def __init__(self) -> None:
        # lot_id → list of authenticated WebSocket connections
        self._rooms: dict[str, list[WebSocket]] = defaultdict(list)

    async def connect(self, lot_id: str, ws: WebSocket) -> None:
        await ws.accept()
        self._rooms[lot_id].append(ws)
        logger.info("WS connected: lot=%s  total=%d", lot_id, len(self._rooms[lot_id]))

    def disconnect(self, lot_id: str, ws: WebSocket) -> None:
        self._rooms[lot_id] = [c for c in self._rooms[lot_id] if c is not ws]
        logger.info("WS disconnected: lot=%s  remaining=%d", lot_id, len(self._rooms[lot_id]))

    async def broadcast(self, lot_id: str, payload: dict) -> None:
        """Send a JSON message to every client in the lot room."""
        message = json.dumps(payload)
        dead: list[WebSocket] = []
        for ws in list(self._rooms.get(lot_id, [])):
            try:
                await ws.send_text(message)
            except Exception:  # noqa: BLE001
                dead.append(ws)
        for ws in dead:
            self.disconnect(lot_id, ws)

    async def broadcast_session_created(
        self,
        lot_id: str,
        *,
        session_id: int,
        license_plate: str,
        confidence: str,
        vehicle_size: str,
        vehicle_color: str,
        spot_number: str,
        entry_time: str,
        rate_per_hour: float,
        image_url: str | None,
        timestamp: str,
    ) -> None:
        await self.broadcast(
            lot_id,
            {
                "type": "session_created",
                "payload": {
                    "session_id": session_id,
                    "license_plate": license_plate,
                    "confidence": confidence,
                    "vehicle_size": vehicle_size,
                    "vehicle_color": vehicle_color,
                    "spot_number": spot_number,
                    "entry_time": entry_time,
                    "rate_per_hour": rate_per_hour,
                    "image_url": image_url,
                    "timestamp": timestamp,
                },
            },
        )


# Singleton shared across the whole application
manager = ConnectionManager()
