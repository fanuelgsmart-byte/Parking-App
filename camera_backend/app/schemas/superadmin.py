"""Pydantic schemas for superadmin endpoints."""
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------
class DashboardStats(BaseModel):
    total_lots: int
    total_spots: int
    occupied_spots: int
    total_active_sessions: int
    total_revenue_all_time: float
    total_revenue_today: float
    total_employees: int
    total_cameras: int
    active_cameras: int


# ---------------------------------------------------------------------------
# Lot Management
# ---------------------------------------------------------------------------
class LotDetail(BaseModel):
    id: str
    name: str
    address: str | None
    timezone: str
    created_at: datetime
    spot_count: int = 0
    occupied_count: int = 0
    camera_count: int = 0
    employee_count: int = 0

    model_config = {"from_attributes": True}


class CreateLotRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=120)
    address: str | None = None
    timezone: str = "UTC"


class UpdateLotRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=120)
    address: str | None = None
    timezone: str | None = None


# ---------------------------------------------------------------------------
# Spot Management
# ---------------------------------------------------------------------------
class CreateSpotRequest(BaseModel):
    spot_number: str = Field(..., min_length=1, max_length=10)
    size: str = Field(..., pattern=r"^(small|medium|large)$")
    row: int | None = None
    col: int | None = None


class UpdateSpotRequest(BaseModel):
    spot_number: str | None = Field(None, min_length=1, max_length=10)
    size: str | None = Field(None, pattern=r"^(small|medium|large)$")
    row: int | None = None
    col: int | None = None


class SpotOut(BaseModel):
    id: int
    lot_id: str
    spot_number: str
    size: str
    status: str
    row: int | None
    col: int | None

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# Cross-lot Reports
# ---------------------------------------------------------------------------
class LotRevenueSummary(BaseModel):
    lot_id: str
    lot_name: str
    total_revenue: float
    total_sessions: int


class CrossLotRevenueReport(BaseModel):
    start_date: datetime
    end_date: datetime
    grand_total_revenue: float
    grand_total_sessions: int
    per_lot: list[LotRevenueSummary]


class LotOccupancySummary(BaseModel):
    lot_id: str
    lot_name: str
    total_spots: int
    occupied_spots: int
    occupancy_rate: float


class CrossLotOccupancyReport(BaseModel):
    total_spots: int
    total_occupied: int
    overall_rate: float
    per_lot: list[LotOccupancySummary]


# ---------------------------------------------------------------------------
# Employee Management
# ---------------------------------------------------------------------------
class EmployeeDetail(BaseModel):
    id: int
    remote_id: str | None
    name: str
    email: str
    role: str
    assigned_lot_id: str | None
    assigned_lot_name: str | None = None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class CreateEmployeeRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=120)
    email: str = Field(..., min_length=3, max_length=254)
    password: str = Field(..., min_length=6)
    role: str = Field("employee", pattern=r"^(employee|manager)$")
    assigned_lot_id: str | None = None


class UpdateEmployeeRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=120)
    email: str | None = Field(None, min_length=3, max_length=254)
    role: str | None = Field(None, pattern=r"^(employee|manager)$")
    assigned_lot_id: str | None = None
    is_active: bool | None = None


# ---------------------------------------------------------------------------
# Camera Overview
# ---------------------------------------------------------------------------
class CameraOverviewItem(BaseModel):
    id: int
    camera_uid: str
    lot_id: str | None
    lot_name: str | None = None
    name: str
    camera_type: str
    is_paired: bool
    is_active: bool
    last_seen_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


class PreRegisterCameraRequest(BaseModel):
    camera_uid: str = Field(..., min_length=1)
    pairing_code: str = Field(..., min_length=4)


# ---------------------------------------------------------------------------
# Audit Log
# ---------------------------------------------------------------------------
class AuditLogEntry(BaseModel):
    id: int
    actor_id: int
    actor_name: str | None = None
    action: str
    entity_type: str
    entity_id: str
    details: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class PaginatedAuditLog(BaseModel):
    total: int
    page: int
    page_size: int
    entries: list[AuditLogEntry]
