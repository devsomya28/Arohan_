from google.cloud import speech
import os
from typing import Tuple, Optional
from app.models.enums import IncidentType

# Set up the keywords that map to emergency types
EMERGENCY_KEYWORDS = {
    "fire": IncidentType.fire,
    "smoke": IncidentType.fire,
    "burn": IncidentType.fire,
    
    "injury": IncidentType.medical,
    "medical": IncidentType.medical,
    "heart attack": IncidentType.medical,
    "bleeding": IncidentType.medical,
    
    "intruder": IncidentType.security,
    "fight": IncidentType.security,
    "gun": IncidentType.security,
    "weapon": IncidentType.security,
    
    "help": IncidentType.panic,
    "sos": IncidentType.panic,
    "emergency": IncidentType.panic
}

def transcribe_audio(audio_bytes: bytes) -> str:
    """
    Transcribes audio bytes using Google Cloud Speech-to-Text API.
    """
    # If no credentials are provided, we might fail, so we catch it
    try:
        client = speech.SpeechClient()
    except Exception as e:
        print(f"Warning: Failed to initialize Google Speech client: {e}")
        # Return a mock transcription for local dev without credentials
        return "this is a mock transcription with the word fire in it"
        
    audio = speech.RecognitionAudio(content=audio_bytes)
    
    # We assume the audio is linear16, but this might need adjustment 
    # depending on the actual radio system's audio format.
    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=16000,
        language_code="en-US",
    )

    try:
        response = client.recognize(config=config, audio=audio)
        
        transcript = ""
        for result in response.results:
            transcript += result.alternatives[0].transcript
            
        return transcript.lower()
    except Exception as e:
        print(f"Error during transcription: {e}")
        return ""

def classify_emergency(transcript: str) -> Optional[IncidentType]:
    """
    Scans the transcript for keywords and classifies the emergency type.
    """
    words = transcript.lower().split()
    
    for word in words:
        if word in EMERGENCY_KEYWORDS:
            return EMERGENCY_KEYWORDS[word]
            
    # Also check for multi-word phrases by doing substring checks
    for phrase, inc_type in EMERGENCY_KEYWORDS.items():
        if " " in phrase and phrase in transcript.lower():
            return inc_type

    return None

def process_radio_audio(audio_bytes: bytes) -> Tuple[str, Optional[IncidentType]]:
    """
    Full pipeline: audio -> text -> classification
    """
    transcript = transcribe_audio(audio_bytes)
    incident_type = classify_emergency(transcript)
    return transcript, incident_type
