from fastapi import APIRouter, HTTPException, status
from typing import List
from app.models.incident import Incident, IncidentUpdate
from app.services.firebase_service import FirebaseService

# Auth disabled for demo – will be re-enabled in production
router = APIRouter(prefix="/incidents", tags=["Incidents"])
firebase = FirebaseService()

@router.get("", response_model=List[Incident])
async def get_all_incidents():
    """
    Returns all active incidents from the Data Fusion Layer.
    """
    incidents_data = firebase.get_all_active_incidents()
    return [Incident(**i) for i in incidents_data]

@router.get("/{id}", response_model=Incident)
async def get_incident(id: str):
    incidents_data = firebase.get_all_active_incidents()
    for i in incidents_data:
        if i.get('id') == id:
            return Incident(**i)
    
    raise HTTPException(status_code=404, detail="Incident not found")

@router.post("/{id}/acknowledge", response_model=Incident)
async def acknowledge_incident(id: str):
    """
    Mark an incident as acknowledged.
    """
    updates = {"status": "acknowledged"}
    firebase.update_incident_status(id, updates)
    
    # Fetch updated incident
    incidents_data = firebase.get_all_active_incidents()
    for i in incidents_data:
        if i.get('id') == id:
            return Incident(**i)
            
    raise HTTPException(status_code=404, detail="Incident not found")

@router.patch("/{id}", response_model=Incident)
async def update_incident(id: str, incident_update: IncidentUpdate):
    update_data = incident_update.model_dump(exclude_unset=True)
    firebase.update_incident_status(id, update_data)
    
    incidents_data = firebase.get_all_active_incidents()
    for i in incidents_data:
        if i.get('id') == id:
            return Incident(**i)
            
    raise HTTPException(status_code=404, detail="Incident not found")
