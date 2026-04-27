from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from typing import Annotated, Optional
from pydantic import BaseModel

from app.services.speech_service import process_radio_audio
from app.services.orchestrator import Orchestrator
from app.models.enums import IncidentType, IncidentSource
from app.models.user import User
from app.dependencies import get_current_active_user

router = APIRouter(prefix="/radio", tags=["Radio Transcription"])
orchestrator = Orchestrator()

class TranscriptionResponse(BaseModel):
    transcript: str
    detected_emergency: Optional[IncidentType] = None
    is_emergency: bool

@router.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe_radio_audio(
    file: UploadFile = File(...)
):
    """
    Auth disabled for demo – will be re-enabled in production
    Receives radio audio file, transcribes it, and triggers Orchestrator if emergency detected.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")
        
    try:
        audio_bytes = await file.read()
        transcript, emergency_type = process_radio_audio(audio_bytes)
        
        # If an emergency was detected in the radio feed, trigger the orchestrator
        if emergency_type:
            await orchestrator.handle_new_event({
                "emergency_type": emergency_type,
                "location": {"floor": 1, "lat": 28.6139, "long": 77.2090}, # Mocked location for radio
                "source": IncidentSource.radio.value,
                "description": f"Radio Transcript: {transcript}"
            })
        
        return TranscriptionResponse(
            transcript=transcript,
            detected_emergency=emergency_type,
            is_emergency=emergency_type is not None
        )
        
    except Exception as e:
        print(f"Transcription error: {e}")
        raise HTTPException(status_code=500, detail="Failed to process radio audio")
