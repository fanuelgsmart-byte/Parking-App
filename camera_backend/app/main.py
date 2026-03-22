"""
ParkFlow Camera Backend — FastAPI application entry point.
"""
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database import create_tables

# API routers
from app.api import auth, camera_ingest, employees, lots, payments, rates, reports, sessions
from app.ws import camera_ws

app = FastAPI(
    title="ParkFlow Camera Backend",
    version="1.0.0",
    description="AI-powered parking management backend with real-time camera integration.",
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Static files (captured vehicle images)
# ---------------------------------------------------------------------------
images_dir = Path(settings.captured_images_dir)
images_dir.mkdir(parents=True, exist_ok=True)
app.mount("/images", StaticFiles(directory=str(images_dir)), name="images")

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
app.include_router(auth.router)
app.include_router(sessions.router)
app.include_router(lots.router)
app.include_router(employees.router)
app.include_router(payments.router)
app.include_router(rates.router)
app.include_router(reports.router)
app.include_router(camera_ingest.router)
app.include_router(camera_ws.router)


# ---------------------------------------------------------------------------
# Startup
# ---------------------------------------------------------------------------
@app.on_event("startup")
def startup():
    create_tables()


@app.get("/health")
def health():
    return {"status": "ok"}
