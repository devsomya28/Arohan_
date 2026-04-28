from pydantic import BaseModel
from typing import List
from app.models.incident import Incident
from app.models.responder import Responder

class DashboardLiveResponse(BaseModel):
    active_incidents: List[Incident]
    active_responders: List[Responder]
