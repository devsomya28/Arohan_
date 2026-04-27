"""
Triage Service — Gemini AI Integration
Uses google-generativeai SDK directly with GEMINI_API_KEY env variable.
Falls back to rule-based triage if API key is missing or Gemini fails.
"""
import json
import os
import requests
from typing import Optional, List
from io import BytesIO
from PIL import Image

from app.models.incident import TriageInput, TriageResult
from app.config import settings

# ── Attempt to initialize Gemini SDK ──
_gemini_model = None
_gemini_error: Optional[str] = None

try:
    import google.generativeai as genai  # type: ignore
    api_key = settings.GEMINI_API_KEY
    if not api_key:
        _gemini_error = "GEMINI_API_KEY is not set in your .env file."
        print(f"[TRIAGE] WARNING: {_gemini_error}")
    else:
        genai.configure(api_key=api_key)
        _gemini_model = genai.GenerativeModel("gemini-1.5-flash-latest")
        print("[TRIAGE] Gemini 1.5 Flash (Latest) initialized successfully.")
except ImportError:
    _gemini_error = "google-generativeai package is not installed. Run: pip install google-generativeai"
    print(f"[TRIAGE] ERROR: {_gemini_error}")
except Exception as e:
    _gemini_error = f"Gemini initialization failed: {e}"
    print(f"[TRIAGE] ERROR: {_gemini_error}")


def get_gemini_status() -> dict:
    """Returns the current Gemini integration status — surfaced in API responses."""
    return {
        "connected": _gemini_model is not None,
        "error": _gemini_error,
    }


def _get_fallback_triage(data: TriageInput) -> TriageResult:
    """
    Rule-based fallback when Gemini is unavailable.
    Classifies by keyword matching on type and description.
    """
    desc = (data.description or "").lower()
    t = (data.type or "").lower()

    if "fire" in desc or "fire" in t or "smoke" in desc:
        return TriageResult(
            classification="fire", severity_score=9,
            recommended_action="Evacuate floor immediately. Dispatch fire team.",
            action_plan=["Sound evacuation alarm", "Dispatch fire response", "Block elevators", "Log to audit trail"],
            triage_source="rule_based"
        )
    elif "blood" in desc or "injury" in desc or "medical" in t or "heart" in desc:
        return TriageResult(
            classification="medical", severity_score=8,
            recommended_action="Dispatch medical team immediately.",
            action_plan=["Send medic to location", "Alert hospital", "Clear path", "Log to audit trail"],
            triage_source="rule_based"
        )
    elif "gun" in desc or "intruder" in desc or "security" in t or "fight" in desc:
        return TriageResult(
            classification="security", severity_score=10,
            recommended_action="Initiate lockdown. Dispatch security.",
            action_plan=["Lockdown all exits", "Alert police", "Evacuate nearby rooms", "Log to audit trail"],
            triage_source="rule_based"
        )
    else:
        return TriageResult(
            classification="panic", severity_score=7,
            recommended_action="SOS received. Dispatch nearest responder.",
            action_plan=["Dispatch responder", "Verify situation", "Escalate if needed", "Log to audit trail"],
            triage_source="rule_based"
        )


def perform_ai_triage(description: str, original_type: str = "unknown", source: str = "app") -> TriageResult:
    """
    Sends incident data to Gemini for intelligent classification.
    Returns category, severity score (1-10), and action plan.
    Falls back to rule-based triage with a clear error if Gemini is unavailable.
    """
    fallback_input = TriageInput(description=description, type=original_type, source=source)

    # ── If Gemini not configured — fail loudly, not silently ──
    if _gemini_model is None:
        error_msg = f"[AI OFFLINE] {_gemini_error or 'Unknown error'}. Using rule-based fallback."
        print(f"[TRIAGE] {error_msg}")
        result = _get_fallback_triage(fallback_input)
        result.ai_error = error_msg  # Attach error so it surfaces in Firebase/UI
        return result

    prompt = f"""You are an expert emergency triage AI for a Smart Hotel Emergency System.

Analyze the following incident report and classify it.

Incident Data:
- Reported Type: {original_type}
- Source: {source}
- Description: {description}

You MUST respond with ONLY a valid JSON object in this exact format:
{{
  "classification": "fire" | "medical" | "security" | "panic",
  "severity_score": <integer 1-10>,
  "recommended_action": "<short 1-sentence action string>",
  "action_plan": ["<step 1>", "<step 2>", "<step 3>"]
}}

Rules:
- severity_score 8-10 = critical (life threatening)
- severity_score 5-7 = high (urgent response needed)
- severity_score 1-4 = moderate (monitoring needed)
- Return ONLY the JSON. No markdown, no explanation."""

    try:
        response = _gemini_model.generate_content(prompt)
        text = response.text.strip()

        # Strip markdown code fences if present
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[1].split("```")[0].strip()

        parsed = json.loads(text)

        # Validate required fields
        if "classification" not in parsed or "severity_score" not in parsed:
            raise ValueError(f"Gemini response missing required fields: {parsed}")

        print(f"[TRIAGE] Gemini classified: {parsed['classification']} | Severity: {parsed['severity_score']}")

        # Robust integer parsing for severity_score
        raw_severity = parsed.get("severity_score", 7)
        try:
            severity = int(raw_severity)
        except (ValueError, TypeError):
            # Fallback for common AI text responses
            mapping = {"critical": 10, "high": 8, "medium": 5, "low": 3}
            severity = mapping.get(str(raw_severity).lower(), 7)

        return TriageResult(
            classification=parsed.get("classification", "panic"),
            severity_score=severity,
            recommended_action=parsed.get("recommended_action", "Respond to incident."),
            action_plan=parsed.get("action_plan", ["Dispatch responder", "Monitor situation"]),
            triage_source="gemini_1.5_flash"
        )

    except Exception as e:
        error_msg = f"Gemini generation FAILED: {e}. Switching to rule-based fallback."
        print(f"[TRIAGE] CRITICAL AI ERROR: {error_msg}")
        result = _get_fallback_triage(fallback_input)
        result.ai_error = error_msg
        return result
def perform_visual_triage(image_urls: List[str], incident_id: str) -> str:
    """
    Fetches evidence images from URLs and uses Gemini 1.5 Flash to describe the scene.
    Returns a human-readable summary for the staff dashboard.
    """
    if _gemini_model is None:
        return "AI Vision Offline: Evidence captured but scene analysis unavailable."

    if not image_urls:
        return "No visual evidence provided for analysis."

    try:
        # 1. Fetch images from Firebase Storage
        images = []
        for url in image_urls[:3]: # Limit to first 3 images for speed
            resp = requests.get(url, timeout=5)
            if resp.status_code == 200:
                images.append(Image.open(BytesIO(resp.content)))

        if not images:
            return "Visual Triage Error: Could not retrieve evidence images."

        # 2. Construct Multimodal Prompt
        prompt = [
            "Analyze these images from a hotel security incident. "
            "Identify any hazards (fire, smoke, weapons), crowd status, and overall severity. "
            "Provide a concise 2-sentence summary for the response team. "
            "Focus only on facts. If no danger is visible, state 'No immediate hazard detected'.",
            *images
        ]

        response = _gemini_model.generate_content(prompt)
        summary = response.text.strip()
        
        print(f"[VISION] Gemini analyzed incident {incident_id}: {summary}")
        return f"AI VISION SUMMARY: {summary}"

    except Exception as e:
        print(f"[VISION] Error during analysis: {e}")
        return "Visual Analysis Pending: AI processing error."
