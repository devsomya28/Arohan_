import asyncio
import time
from .firebase_service import FirebaseService

class EscalationService:
    def __init__(self):
        self.firebase = FirebaseService()
        self._running = False

    async def start_monitoring(self):
        """
        Background task to monitor for unacknowledged incidents.
        """
        self._running = True
        print("Escalation Watchdog: ACTIVE (30s threshold)")
        
        while self._running:
            try:
                # 1. Fetch all active incidents (run blocking call in thread)
                incidents = await asyncio.to_thread(self.firebase.get_all_active_incidents)
                
                now = time.time()
                for incident in incidents:
                    # Skip if already acknowledged or escalated
                    if incident.get("status") != "active" or incident.get("escalated"):
                        continue
                        
                    # 2. Check elapsed time
                    created_at = self._parse_timestamp(incident.get("timestamp"))
                    elapsed = now - created_at
                    
                    if elapsed > 30: # 30 Second Rule
                        await self._escalate_incident(incident)
                
                await asyncio.sleep(5) # Check every 5 seconds
            except Exception as e:
                print(f"Watchdog Error: {e}")
                await asyncio.sleep(10)

    def _parse_timestamp(self, ts_str: str) -> float:
        # Simplified parser for ISO strings to epoch
        try:
            from dateutil import parser
            dt = parser.parse(ts_str)
            return dt.timestamp()
        except:
            return time.time() # Fallback

    async def _escalate_incident(self, incident: dict):
        print(f"WATCHDOG: ESCALATING INCIDENT {incident.get('id')} - NO ACK IN 30S")
        
        # 1. Mark as escalated in DB
        await asyncio.to_thread(
            self.firebase.update_incident_status,
            incident.get('id'),
            {
                "escalated": True,
                "escalation_reason": "NO_RESPONDER_ACK_TIMEOUT",
                "status": "escalated"
            }
        )
        
        # 2. Trigger Multi-channel External Alert (112 Mock)
        # In production, this calls the Twilio/WhatsApp API
        print(f"CRITICAL: 112 Emergency Services notified for {incident.get('type')} at Floor {incident.get('location', {}).get('floor')}")

    def stop(self):
        self._running = False
