"""
ALPR pipeline wrapping fast-alpr.

Returns structured results for each license plate detected in a frame.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass

import cv2
import numpy as np

logger = logging.getLogger(__name__)

# Lazy-load the ALPR model so startup is fast; first request pays the load cost.
_alpr = None


def _get_alpr():
    global _alpr  # noqa: PLW0603
    if _alpr is None:
        try:
            from fast_alpr import ALPR  # type: ignore[import]
            _alpr = ALPR(
                detector_model="yolo-v9-t-384-license-plate-end2end",
                ocr_model="cct-xs-v1-global-model",
            )
            logger.info("ALPR model loaded.")
        except Exception as exc:  # noqa: BLE001
            logger.error("Could not load ALPR model: %s", exc)
            _alpr = None
    return _alpr


@dataclass
class DetectedPlate:
    license_plate: str
    confidence: str          # 'high' / 'medium' / 'low'
    confidence_score: float  # 0.0–1.0
    # Bounding box of the vehicle/plate in the original frame (x1, y1, x2, y2)
    bbox: tuple[int, int, int, int]


def run(frame_bytes: bytes) -> list[DetectedPlate]:
    """
    Decode JPEG bytes and run the full ALPR pipeline.

    Returns a (possibly empty) list of DetectedPlate results.
    """
    alpr = _get_alpr()
    if alpr is None:
        logger.warning("ALPR unavailable; returning empty results.")
        return []

    nparr = np.frombuffer(frame_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if frame is None:
        logger.warning("Could not decode image bytes.")
        return []

    try:
        results = alpr.predict(frame)
    except Exception as exc:  # noqa: BLE001
        logger.error("ALPR prediction failed: %s", exc)
        return []

    plates: list[DetectedPlate] = []
    for result in results:
        if result.ocr_result is None or not result.ocr_result.ocr_text:
            continue

        score: float = float(result.ocr_result.confidence or 0.0)
        if score >= 0.80:
            confidence_label = "high"
        elif score >= 0.50:
            confidence_label = "medium"
        else:
            confidence_label = "low"

        det = result.detection_result
        x1, y1, x2, y2 = (
            int(det.bounding_box.x1),
            int(det.bounding_box.y1),
            int(det.bounding_box.x2),
            int(det.bounding_box.y2),
        )

        plates.append(
            DetectedPlate(
                license_plate=result.ocr_result.ocr_text.strip().upper(),
                confidence=confidence_label,
                confidence_score=score,
                bbox=(x1, y1, x2, y2),
            )
        )

    return plates
