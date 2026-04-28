"""
Photo Upload Router — receives images from Flutter camera and stores in MongoDB.
Photos are base64-encoded and stored alongside incident data.
"""
import base64
import time
import logging
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import Optional
from app.database import get_collection
from app.services.firebase_service import get_realtime_db

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/photos", tags=["Photos"])

@router.post("/upload")
async def upload_incident_photo(
    incident_id: str = Form(...),
    user_id: str = Form("guest"),
    description: str = Form(""),
    file: UploadFile = File(...)
):
    """
    Receives a photo from the Flutter app, stores it in MongoDB,
    and updates the incident in Firebase RTDB so staff can see it.
    """
    # Validate file type
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files are accepted.")
    
    # Read file bytes
    file_bytes = await file.read()
    if len(file_bytes) > 10 * 1024 * 1024:  # 10MB limit
        raise HTTPException(status_code=413, detail="Image too large. Max 10MB.")
    
    # Encode to base64 for MongoDB storage
    b64_data = base64.b64encode(file_bytes).decode("utf-8")
    
    timestamp = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    
    photo_doc = {
        "incident_id": incident_id,
        "user_id": user_id,
        "description": description,
        "filename": file.filename,
        "content_type": file.content_type,
        "data_base64": b64_data,
        "timestamp": timestamp,
        "size_bytes": len(file_bytes),
    }
    
    # Save to MongoDB
    photo_id = f"photo_{int(time.time())}"
    collection = get_collection("incident_photos")
    if collection is not None:
        result = await collection.insert_one(photo_doc)
        photo_id = str(result.inserted_id)
        logger.info(f"Photo saved to MongoDB: {photo_id}")
    else:
        logger.warning("MongoDB not connected — photo not persisted to DB")
    
    # Update Firebase RTDB so the staff dashboard shows there's a photo attached
    try:
        rdb = get_realtime_db()
        if rdb:
            rdb.child("incidents").child(incident_id).child("photos").child(photo_id).set({
                "photo_id": photo_id,
                "timestamp": timestamp,
                "user_id": user_id,
                "description": description,
                "filename": file.filename,
                # We don't put base64 in Firebase (too large) — just metadata
            })
            logger.info(f"Photo metadata pushed to Firebase RTDB for incident {incident_id}")
    except Exception as e:
        logger.warning(f"Firebase RTDB update failed (non-critical): {e}")
    
    return {
        "success": True,
        "photo_id": photo_id,
        "incident_id": incident_id,
        "message": "Photo uploaded and linked to incident successfully."
    }

@router.get("/incident/{incident_id}")
async def get_incident_photos(incident_id: str):
    """
    Returns all photo metadata for a given incident.
    Base64 data is excluded from list view for performance.
    """
    collection = get_collection("incident_photos")
    if collection is None:
        return {"photos": [], "error": "MongoDB not connected"}
    
    cursor = collection.find(
        {"incident_id": incident_id},
        {"data_base64": 0}  # Exclude large base64 from list
    )
    photos = await cursor.to_list(length=50)
    for p in photos:
        p["_id"] = str(p["_id"])
    
    return {"incident_id": incident_id, "photos": photos, "count": len(photos)}

@router.get("/image/{photo_id}")
async def get_photo_image(photo_id: str):
    """
    Returns the actual base64 image data for display.
    """
    from bson import ObjectId
    collection = get_collection("incident_photos")
    if collection is None:
        raise HTTPException(status_code=503, detail="MongoDB not connected")
    
    try:
        doc = await collection.find_one({"_id": ObjectId(photo_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid photo ID")
    
    if not doc:
        raise HTTPException(status_code=404, detail="Photo not found")
    
    return {
        "photo_id": photo_id,
        "incident_id": doc["incident_id"],
        "content_type": doc["content_type"],
        "data_base64": doc["data_base64"],
        "timestamp": doc["timestamp"],
        "description": doc.get("description", ""),
    }
