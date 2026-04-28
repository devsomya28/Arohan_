from fastapi import APIRouter, HTTPException, status
from app.models.incident import Incident, IoTWebhookPayload
from app.models.enums import IncidentSource
from app.services.orchestrator import Orchestrator

router = APIRouter(prefix="/iot", tags=["IoT Webhooks"])
orchestrator = Orchestrator()

@router.post("/webhook", response_model=Incident, status_code=status.HTTP_201_CREATED)
async def iot_webhook(payload: IoTWebhookPayload):
    """
    Webhook endpoint for IoT devices.
    Uses Orchestrator for end-to-end processing and deduplication.
    """
    # Use the fused orchestrator which handles idempotency and AI triage
    incident = await orchestrator.handle_new_event({
        "emergency_type": payload.event_type,
        "location": payload.location.dict() if hasattr(payload.location, 'dict') else payload.location,
        "source": IncidentSource.iot.value,
        "device_id": payload.device_id
    })

    if not incident:
        # If incident is None, it was fused/deduplicated
        raise HTTPException(
            status_code=status.HTTP_200_OK, 
            detail="Incident fused with existing active event."
        )

    return incident
