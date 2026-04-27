from pydantic import BaseModel
from typing import List
from enum import Enum

class TargetAudience(str, Enum):
    staff = "staff"
    guests = "guests"
    emergency_services = "emergency_services"

class AlertRequest(BaseModel):
    incident_id: str
    message: str
    targets: List[TargetAudience]

class AlertResponse(BaseModel):
    message: str
    alert_id: str

class AckRequest(BaseModel):
    alert_id: str

class EscalationRequest(BaseModel):
    incident_id: str

