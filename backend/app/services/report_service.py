import time
import json
from .firebase_service import FirebaseService

class ReportService:
    def __init__(self):
        self.firebase = FirebaseService()

    async def generate_incident_report(self, incident_id: str) -> dict:
        """
        Gathers all mission data and generates a structured Audit Report.
        """
        # 1. Fetch incident from Firestore (Audit Record)
        # Using mock fetching for now since we have the base
        incidents = self.firebase.get_all_active_incidents()
        incident = next((i for i in incidents if i['id'] == incident_id), None)
        
        if not incident:
            return {"error": "Incident not found"}

        # 2. Calculate Mission Analytics
        report = {
            "mission_id": incident_id,
            "tactical_summary": {
                "type": incident.get("type", "UNKNOWN"),
                "source": incident.get("source", "UNKNOWN"),
                "location": f"Floor {incident.get('location', {}).get('floor', 0)}",
                "severity_score": incident.get("severity", 0)
            },
            "timeline": [
                {"time": incident.get("timestamp"), "event": "Incident Detected"},
                {"time": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), "event": "Final Audit Generated"}
            ],
            "compliance_status": "CERTIFIED_NDMA_INDIA" if not incident.get("escalated") else "ESCALATED_TO_112",
            "footer": "AAROHAN AI AOCC COMMAND CENTER - AUTOMATED REPORT"
        }
        
        # 3. Save report back to Firestore
        self.firebase.fs.collection('reports').document(incident_id).set(report)
        
        return report
