from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from enum import Enum

class IncidentType(str, Enum):
    FIRE = "fire"
    IOT = "iot"
    RADIO = "radio"
    SOS = "sos"
    PANIC = "panic"
    SMOKE = "smoke"

class IncidentSource(str, Enum):
    CCTV = "cctv"
    IOT = "iot"
    RADIO = "radio"
    APP = "app"
    GUEST = "guest"

class IncidentStatus(str, Enum):
    PENDING = "pending"
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    ESCALATED = "escalated"

class Location(BaseModel):
    lat: float
    long: float
    floor: Optional[int] = None

class IncidentBase(BaseModel):
    type: str 
    severity: int = Field(..., ge=1, le=10)
    location: Location
    source: str
    status: str = "active"
    escalated: bool = False
    assigned_to: Optional[str] = None
    ai_analysis: Optional[str] = None
    ai_error: Optional[str] = None
    triage_source: Optional[str] = None

    def toJson(self) -> Dict[str, Any]:
        return self.model_dump()

class IncidentCreate(IncidentBase):
    pass

class IncidentUpdate(BaseModel):
    type: Optional[str] = None
    severity: Optional[int] = None
    location: Optional[Location] = None
    status: Optional[str] = None
    escalated: Optional[bool] = None

class SOSCreate(BaseModel):
    user_id: str
    location: Location
    emergency_type: str
    source: Optional[str] = None
    phone: Optional[Any] = None

class IoTWebhookPayload(BaseModel):
    device_id: str
    event_type: str
    location: Location
    event_id: Optional[str] = None

class TriageInput(BaseModel):
    description: Optional[str] = None
    type: Optional[str] = "unknown"
    source: Optional[str] = "app"

class TriageResult(BaseModel):
    classification: str
    severity_score: int
    recommended_action: str
    action_plan: List[str] = []
    triage_source: str = "rule_based"
    ai_error: Optional[str] = None

class Incident(IncidentBase):
    id: Optional[str] = None
    timestamp: str

    @classmethod
    def from_dict(cls, data: Dict[str, Any]):
        return cls(**data)
