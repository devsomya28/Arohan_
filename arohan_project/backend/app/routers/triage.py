from fastapi import APIRouter, Depends
from typing import Annotated

from app.models.incident import TriageInput, TriageResult
from app.models.user import User
from app.dependencies import get_current_active_user
from app.services.triage_service import perform_ai_triage, perform_visual_triage
from pydantic import BaseModel
from typing import List
import firebase_admin
from firebase_admin import db

router = APIRouter(prefix="/triage", tags=["AI Triage"])

@router.post("", response_model=TriageResult)
async def analyze_incident(
    data: TriageInput,
    current_user: Annotated[User, Depends(get_current_active_user)]
):
    """
    AI-powered triage engine.
    Analyzes incident descriptions using Gemini (Vertex AI) to automatically
    classify the emergency type, determine severity, and recommend actions.
    Includes fallback rule-based logic if AI is unavailable.
    """
    result = perform_ai_triage(data)
    return result
class VisualTriageRequest(BaseModel):
    incident_id: str
    image_urls: List[str]

@router.post("/visual")
async def analyze_visual_evidence(data: VisualTriageRequest):
    """
    Multimodal AI triage.
    Analyzes evidence photos using Gemini Vision and updates the incident dashboard.
    """
    summary = perform_visual_triage(data.image_urls, data.incident_id)
    
    # Write back to Firebase for real-time staff update
    try:
        ref = db.reference(f"incidents/{data.incident_id}")
        ref.update({
            "ai_analysis": summary,
            "visual_analysis_complete": True
        })
    except Exception as e:
        print(f"[FIREBASE] Failed to update visual analysis: {e}")

    return {"incident_id": data.incident_id, "ai_visual_analysis": summary}
