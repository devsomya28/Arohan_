import time
import logging
from typing import Dict, Any, List, Optional
from ..models.incident import Incident, Location, IncidentStatus
from .firebase_service import FirebaseService
from .firebase_service import FirebaseService
from .triage_service import perform_ai_triage
from .routing_service import find_nearest_responder_live
from .routing_service import Location as RoutingLocation
from .notification_service import NotificationService

logger = logging.getLogger(__name__)

class Orchestrator:
    def __init__(self):
        self.firebase = FirebaseService()
        self.notifier = NotificationService()
        self._recent_events: List[Dict[str, Any]] = []

    async def handle_new_event(self, event_data: Dict[str, Any]) -> Optional[Incident]:
        normalized_event = self._normalize_event(event_data)
        
        if self._is_duplicate(normalized_event):
            logger.info(f"Fusion: Deduplicated event from {normalized_event['source']}")
            return None
        
        # 🛡️ DEBUG SIGNAL
        logger.info(f"DEBUG EVENT: {normalized_event}")
        
        emergency_label = normalized_event.get("type", "unknown")
        logger.info(f"Orchestrator: Processing event '{emergency_label}' from {normalized_event.get('source', 'unknown')}")
        
        description = normalized_event.get("description") or f"Emergency triggered: {emergency_label}"
        logger.info("Orchestrator: Step 1 - Triggering AI Triage...")
        triage_result = perform_ai_triage(
            description=description,
            original_type=emergency_label,
            source=normalized_event.get("source", "unknown")
        )
        logger.info(f"Orchestrator: Triage Complete - {triage_result.classification}")
        
        logger.info("Orchestrator: Step 2 - Finding nearest responder...")
        # 🎯 Find nearest responder from Live Database (Safe Mode)
        assigned_to = "AOCC_CENTRAL_DISPATCH"
        try:
            loc = RoutingLocation(
                lat=normalized_event["location"].get("lat", 0),
                long=normalized_event["location"].get("long", 0),
                floor=normalized_event["location"].get("floor", 1)
            )
            staff, dist, eta = await find_nearest_responder_live(triage_result.classification, loc)
            if staff:
                assigned_to = staff.get('name', "AOCC_CENTRAL_DISPATCH")
        except Exception as e:
            logger.warning(f"Orchestrator: Routing failed: {e}")

        logger.info(f"Orchestrator: Step 3 - Creating Incident Object (Assigned to: {assigned_to})...")
        incident = Incident(
            type=triage_result.classification,
            severity=triage_result.severity_score,
            location=Location(**normalized_event["location"]),
            source=normalized_event["source"],
            status=IncidentStatus.ACTIVE,
            timestamp=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
            escalated=False,
            assigned_to=assigned_to,
            ai_analysis=triage_result.recommended_action,
            ai_error=getattr(triage_result, 'ai_error', None),
            triage_source=getattr(triage_result, 'triage_source', 'rule_based'),
        )
        
        logger.info("Orchestrator: Step 4 - Saving to Firebase...")
        created_incident = self.firebase.create_incident(incident)
        logger.info(f"Orchestrator: Incident saved with ID: {getattr(created_incident, 'id', 'unknown')}")
        
        # 🚀 Dispatch Production-Grade alerts asynchronously
        try:
            import asyncio
            # Prepare contact list
            phones = []
            if normalized_event.get("phone"):
                if isinstance(normalized_event["phone"], list):
                    phones.extend(normalized_event["phone"])
                else:
                    phones.append(normalized_event["phone"])
            
            # Also fetch staff numbers
            try:
                from .twilio_service import get_staff_phone_numbers
                staff_phones = await get_staff_phone_numbers()
                phones.extend(staff_phones)
            except:
                pass
            
            if phones:
                asyncio.create_task(self.notifier.dispatch_emergency_alerts(
                    incident_id=str(created_incident.id or "unknown"),
                    incident_type=created_incident.type,
                    severity=created_incident.severity,
                    location=normalized_event["location"],
                    phone_numbers=list(set(phones)) # Deduplicate
                ))
        except Exception as e:
            logger.warning(f"Notification dispatch failed: {e}")
        
        self._recent_events.append({
            "timestamp": time.time(),
            "location": normalized_event["location"],
            "type": normalized_event["type"]
        })
        if len(self._recent_events) > 100:
            self._recent_events.pop(0)
        
        return created_incident

    def _normalize_event(self, data: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "type": data.get("emergency_type") or data.get("type", "unknown"),
            "location": data.get("location", {"lat": 0, "long": 0, "floor": 1}),
            "source": data.get("source", "unknown"),
            "description": data.get("description"),
            "user_id": data.get("user_id"),
            "phone": data.get("phone")
        }

    def _is_duplicate(self, event: Dict[str, Any]) -> bool:
        now = time.time()
        for recent in self._recent_events:
            if now - recent["timestamp"] < 60:
                if event["location"].get("floor") == recent["location"].get("floor"):
                    if event["type"] == recent["type"]:
                        return True
        return False


