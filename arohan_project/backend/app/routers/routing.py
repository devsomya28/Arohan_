from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated

from app.models.responder import RouteRequest, RouteResponse
from app.models.user import User
from app.dependencies import get_current_active_user
from app.services.routing_service import find_nearest_responder_live

router = APIRouter(prefix="/route", tags=["Responder Routing"])

@router.post("", response_model=RouteResponse)
async def assign_responder(
    request: RouteRequest,
    current_user: Annotated[User, Depends(get_current_active_user)]
):
    """
    Routing engine endpoint.
    Calculates the Haversine distance between the incident and available staff.
    Assigns the nearest responder with the matching role to the emergency.
    """
    # Call the new async live database search
    responder, distance, eta = await find_nearest_responder_live(request.incident_type, request.incident_location)
    
    if not responder:
        return RouteResponse(
            message=f"Alert: No available responders found for type '{request.incident_type}'."
        )
        
    return RouteResponse(
        assigned_responder_id=str(responder.get('_id', 'unknown')),
        assigned_responder_role=responder.get('role', 'general'),
        distance_km=round(distance, 3),
        eta_minutes=eta,
        message="Responder assigned successfully from Live Database."
    )
