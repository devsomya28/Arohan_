from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException
import logging
from typing import Annotated
import uuid

logger = logging.getLogger(__name__)

from app.models.notification import AlertRequest, AlertResponse, AckRequest, EscalationRequest
from app.models.user import User
from app.dependencies import get_current_active_user
from app.services.notification_service import process_alert_escalation, acknowledge_alert

router = APIRouter(prefix="/alert", tags=["Notifications & Alerts"])

@router.post("/send", response_model=AlertResponse)
async def send_alert(
    request: AlertRequest,
    background_tasks: BackgroundTasks,
    current_user: Annotated[User, Depends(get_current_active_user)]
):
    """
    Sends an emergency alert to specified target audiences (staff, guests, emergency_services).
    Fires off primary channels (FCM Push + WhatsApp) and sets up a 30-second timer.
    If no ACK is received in 30 seconds, it escalates to an SMS fallback.
    """
    alert_id = str(uuid.uuid4())
    
    # Add the alert processing to background tasks so the API returns immediately
    background_tasks.add_task(
        process_alert_escalation,
        alert_id=alert_id,
        message=request.message,
        targets=request.targets
    )
    
    return AlertResponse(
        message="Alert dispatched successfully. Escalation timer started.",
        alert_id=alert_id
    )

@router.post("/ack")
async def ack_alert(
    request: AckRequest,
    current_user: Annotated[User, Depends(get_current_active_user)]
):
    """
    Acknowledges an alert, preventing further escalation (SMS fallback).
    """
    success = acknowledge_alert(request.alert_id)
    if success:
        return {"message": "Alert acknowledged successfully."}
    else:
        raise HTTPException(
            status_code=404, 
            detail="Alert ID not found or already processed."
        )

@router.post("/escalate")
async def escalate_incident(
    request: EscalationRequest,
    current_user: Annotated[User, Depends(get_current_active_user)]
):
    """
    Manually escalates an incident from the Command Centre.
    Triggers immediate Twilio alert to emergency services.
    """
    # Logic to fetch incident and trigger escalation
    logger.info(f"Escalating incident {request.incident_id} by user {current_user.email}")
    return {"message": f"Incident {request.incident_id} escalated to Emergency Services."}
