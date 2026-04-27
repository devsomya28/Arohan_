import logging
from fastapi import APIRouter, HTTPException, status, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

logger = logging.getLogger(__name__)

from app.models.incident import Incident, SOSCreate
from app.models.enums import IncidentSource
from app.services.orchestrator import Orchestrator

router = APIRouter(prefix="/sos", tags=["Guest SOS"])
orchestrator = Orchestrator()

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)

@router.post("", response_model=Incident, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def create_sos_alert(request: Request, sos_in: SOSCreate):
    """
    Guest or Machine endpoint to trigger an SOS alert.
    Automatically assigns high severity and routes through orchestrator.
    """
    actual_source = sos_in.source or IncidentSource.sos
    
    logger.info(f"GUEST_SOS: Received request from {sos_in.user_id}")
    try:
        # Pass to fused orchestrator
        logger.info("GUEST_SOS: Handing over to Orchestrator...")
        incident = await orchestrator.handle_new_event({
            "emergency_type": sos_in.emergency_type,
            "location": sos_in.location.model_dump() if hasattr(sos_in.location, 'model_dump') else sos_in.location,
            "source": actual_source.value,
            "user_id": sos_in.user_id,
            "phone": sos_in.phone
        })
        logger.info(f"GUEST_SOS: Orchestrator success. Incident ID: {getattr(incident, 'id', 'unknown')}")
    except Exception as e:
        logger.error(f"GUEST_SOS: CRITICAL ERROR IN ORCHESTRATOR: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal Server Error in Orchestrator: {str(e)}")

    if not incident:
        raise HTTPException(status_code=200, detail="Event fused with existing active incident.")

    return incident
