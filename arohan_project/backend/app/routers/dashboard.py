from fastapi import APIRouter, Depends
from typing import Annotated

from app.models.dashboard import DashboardLiveResponse
from app.models.incident import Incident
from app.models.user import User
from app.dependencies import get_current_active_user
from app.services.firebase_service import get_firestore_client
from app.services.routing_service import mock_responders

from fastapi import APIRouter
from app.models.dashboard import DashboardLiveResponse
from app.models.incident import Incident
from app.services.firebase_service import FirebaseService
from app.services.routing_service import mock_responders

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])
firebase = FirebaseService()

@router.get("/live", response_model=DashboardLiveResponse)
async def get_dashboard_live():
    """
    Returns the real-time state for the monitoring dashboard.
    """
    incidents_data = firebase.get_all_active_incidents()
    active_incidents = [Incident(**i) for i in incidents_data if i.get('status') != 'resolved']
            
    # Fetch live responders (using the mock database from routing service)
    active_responders = [r for r in mock_responders if r.availability]
    
    return DashboardLiveResponse(
        active_incidents=active_incidents,
        active_responders=active_responders
    )
