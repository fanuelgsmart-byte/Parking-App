"""
Atomic session creation triggered by camera detection.

On each plate detection:
  1. Skip if the plate already has an active session in this lot.
  2. Find the best matching available spot.
  3. Insert vehicle + session in a single DB transaction.
  4. Mark the spot as occupied.
  5. Return the created session (or None if skipped/no spot).
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.session import ParkingSession
from app.models.spot import ParkingSpot
from app.models.vehicle import Vehicle

logger = logging.getLogger(__name__)

_OPEN_STATUSES = ("active", "flagged_for_checkout", "payment_pending")


def get_active_rate(db: Session, lot_id: str, vehicle_size: str) -> float:
    """Return the current rate per hour for this lot + size, defaulting to 0."""
    from app.models.rate import ParkingRate  # avoid circular at module level

    now = datetime.now(timezone.utc)
    rate = (
        db.query(ParkingRate)
        .filter(
            ParkingRate.lot_id == lot_id,
            ParkingRate.vehicle_size == vehicle_size,
            ParkingRate.is_active.is_(True),
            ParkingRate.effective_from <= now,
        )
        .order_by(ParkingRate.effective_from.desc())
        .first()
    )
    return rate.rate_per_hour if rate else 0.0


def _already_parked(db: Session, license_plate: str, lot_id: str) -> bool:
    return (
        db.query(ParkingSession)
        .join(Vehicle)
        .filter(
            Vehicle.license_plate == license_plate,
            ParkingSession.lot_id == lot_id,
            ParkingSession.status.in_(_OPEN_STATUSES),
        )
        .first()
    ) is not None


def _find_spot(db: Session, lot_id: str, vehicle_size: str) -> ParkingSpot | None:
    # Exact size match first
    spot = (
        db.query(ParkingSpot)
        .filter(
            ParkingSpot.lot_id == lot_id,
            ParkingSpot.status == "available",
            ParkingSpot.size == vehicle_size,
        )
        .order_by(ParkingSpot.spot_number)
        .first()
    )
    if spot:
        return spot
    # Fallback: any available spot
    return (
        db.query(ParkingSpot)
        .filter(ParkingSpot.lot_id == lot_id, ParkingSpot.status == "available")
        .order_by(ParkingSpot.spot_number)
        .first()
    )


def create_session_from_camera(
    db: Session,
    *,
    license_plate: str,
    vehicle_size: str,
    vehicle_color: str,
    lot_id: str,
    image_url: str | None = None,
) -> ParkingSession | None:
    """
    Create a parking session triggered by camera detection.

    Returns the new ParkingSession, or None if the vehicle is already parked
    or no spot is available.
    """
    if _already_parked(db, license_plate, lot_id):
        logger.debug("Plate %s already has an active session in lot %s — skipped.", license_plate, lot_id)
        return None

    spot = _find_spot(db, lot_id, vehicle_size)
    if spot is None:
        logger.warning("No available spot for size=%s in lot %s.", vehicle_size, lot_id)
        return None

    now = datetime.now(timezone.utc)

    vehicle = Vehicle(
        license_plate=license_plate,
        size=vehicle_size,
        color=vehicle_color,
        image_url=image_url,
    )
    db.add(vehicle)
    db.flush()  # get vehicle.id

    session = ParkingSession(
        vehicle_id=vehicle.id,
        spot_id=spot.id,
        lot_id=lot_id,
        entry_time=now,
        status="active",
        is_synced=False,
    )
    db.add(session)

    spot.status = "occupied"
    db.commit()
    db.refresh(session)
    db.refresh(spot)
    db.refresh(vehicle)
    logger.info("Session %d created for plate %s at spot %s.", session.id, license_plate, spot.spot_number)
    return session
