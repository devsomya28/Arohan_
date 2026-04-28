from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class IncidentReport(BaseModel):
    incident_id: str
    incident_type: str
    severity: int
    escalation_count: int
    created_at: datetime
    assigned_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    response_time_seconds: Optional[int] = None
    resolution_time_seconds: Optional[int] = None
