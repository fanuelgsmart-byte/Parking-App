"""
Estimates vehicle colour and size from a bounding box crop.

Colour  — dominant HSV hue analysis on the vehicle body region.
Size    — bounding box area relative to the full frame area.
"""
from __future__ import annotations

import cv2
import numpy as np


# ---------------------------------------------------------------------------
# Colour detection
# ---------------------------------------------------------------------------

# HSV ranges: (lower, upper, name)
_COLOUR_RANGES: list[tuple[np.ndarray, np.ndarray, str]] = [
    (np.array([0, 70, 50]),   np.array([10, 255, 255]),  "red"),
    (np.array([170, 70, 50]), np.array([180, 255, 255]), "red"),
    (np.array([11, 70, 50]),  np.array([25, 255, 255]),  "orange"),
    (np.array([26, 70, 50]),  np.array([34, 255, 255]),  "yellow"),
    (np.array([35, 50, 50]),  np.array([85, 255, 255]),  "green"),
    (np.array([86, 50, 50]),  np.array([130, 255, 255]), "blue"),
    (np.array([131, 50, 50]), np.array([160, 255, 255]), "purple"),
    (np.array([0, 0, 200]),   np.array([180, 30, 255]),  "white"),
    (np.array([0, 0, 0]),     np.array([180, 30, 50]),   "black"),
    (np.array([0, 0, 51]),    np.array([180, 30, 199]),  "silver"),
]


def detect_colour(frame: np.ndarray, bbox: tuple[int, int, int, int]) -> str:
    """Return the dominant colour name for the vehicle region."""
    x1, y1, x2, y2 = bbox
    h, w = frame.shape[:2]
    x1, y1 = max(0, x1), max(0, y1)
    x2, y2 = min(w, x2), min(h, y2)

    crop = frame[y1:y2, x1:x2]
    if crop.size == 0:
        return "unknown"

    # Resize to speed up analysis
    crop = cv2.resize(crop, (64, 64))
    hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)

    best_name = "unknown"
    best_count = 0
    for lower, upper, name in _COLOUR_RANGES:
        mask = cv2.inRange(hsv, lower, upper)
        count = int(np.sum(mask > 0))
        if count > best_count:
            best_count = count
            best_name = name

    return best_name


# ---------------------------------------------------------------------------
# Size estimation
# ---------------------------------------------------------------------------

# Thresholds: fraction of total frame area occupied by the vehicle bbox.
_LARGE_THRESHOLD = 0.20   # ≥20 % of frame → large
_SMALL_THRESHOLD = 0.06   # < 6 % of frame → small
                           # between 6–20 % → medium


def estimate_size(frame: np.ndarray, bbox: tuple[int, int, int, int]) -> str:
    """Return 'small', 'medium', or 'large' based on the bbox area ratio."""
    x1, y1, x2, y2 = bbox
    frame_area = frame.shape[0] * frame.shape[1]
    if frame_area == 0:
        return "medium"

    bbox_area = max(0, x2 - x1) * max(0, y2 - y1)
    ratio = bbox_area / frame_area

    if ratio >= _LARGE_THRESHOLD:
        return "large"
    if ratio < _SMALL_THRESHOLD:
        return "small"
    return "medium"
