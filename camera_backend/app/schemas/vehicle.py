from datetime import datetime

from pydantic import BaseModel


class VehicleOut(BaseModel):
    id: int
    license_plate: str
    size: str
    color: str
    image_url: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
