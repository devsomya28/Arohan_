from pydantic import BaseModel
from typing import Optional
from .incident import Location
from enum import Enum

class ResponderRole(str, Enum):
    fire_team = "fire team"
    medic = "medic"
    guard = "guard"
    general = "general"

class Responder(BaseModel):
    id: str
    role: ResponderRole
    live_location: Location
    availability: bool = True

class RouteRequest(BaseModel):
    incident_id: str
    incident_type: str  # e.g. "fire", "medical", "security"
    incident_location: Location

class RouteResponse(BaseModel):
    assigned_responder_id: Optional[str] = None
    assigned_responder_role: Optional[ResponderRole] = None
    distance_km: Optional[float] = None
    eta_minutes: Optional[int] = None
    message: str
