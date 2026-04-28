import logging
from typing import List, Dict, Any
from app.config import settings

logger = logging.getLogger(__name__)

class NotificationService:
    def __init__(self):
        self.sid = settings.TWILIO_ACCOUNT_SID
        self.token = settings.TWILIO_AUTH_TOKEN
        self.whatsapp_from = settings.TWILIO_WHATSAPP_FROM
        self.sms_from = settings.TWILIO_FROM_NUMBER
        
        # Initialize Twilio Client only if credentials exist
        self.client = None
        if self.sid and self.token:
            try:
                from twilio.rest import Client
                self.client = Client(self.sid, self.token)
                logger.info("Twilio Client Initialized Successfully.")
            except Exception as e:
                logger.error(f"Twilio Client Init Failed: {e}")

    async def dispatch_emergency_alerts(self, incident_id: str, incident_type: str, severity: int, location: Dict[str, Any], phone_numbers: List[str]):
        """
        Main entry point for dispatching multi-channel alerts.
        """
        lat = location.get('lat')
        lng = location.get('long')
        maps_link = f"https://www.google.com/maps/search/?api=1&query={lat},{lng}" if lat and lng else "No coordinates."

        message = (
            f"🚨 AAROHAN AI SOS - #{incident_id}\n"
            f"━━━━━━━━━━━━━━━\n"
            f"TYPE: {incident_type.upper()}\n"
            f"SEVERITY: {severity}/10\n"
            f"FLOOR: {location.get('floor', 'N/A')}\n"
            f"📍 MAP: {maps_link}\n"
            f"━━━━━━━━━━━━━━━\n"
            f"RESPOND IMMEDIATELY"
        )

        if not self.client:
            logger.info(f"[MOCK ALERT] Numbers: {phone_numbers}\n{message}")
            return

        for raw_number in phone_numbers:
            # 🛡️ NORMALIZER: Strip spaces and dashes for Twilio E.164 compliance
            number = "".join(c for c in str(raw_number) if c.isdigit() or c == "+")
            
            # 1. Send WhatsApp
            if self.whatsapp_from:
                try:
                    to_whatsapp = f"whatsapp:{number}" if not number.startswith('whatsapp:') else number
                    from_whatsapp = f"whatsapp:{self.whatsapp_from}" if not self.whatsapp_from.startswith('whatsapp:') else self.whatsapp_from
                    
                    self.client.messages.create(
                        body=message,
                        from_=from_whatsapp,
                        to=to_whatsapp
                    )
                    logger.info(f"✅ WhatsApp Alert sent to {number}")
                except Exception as e:
                    logger.error(f"❌ WhatsApp Failed for {number}: {e}")

            # 2. Send SMS
            if self.sms_from:
                try:
                    self.client.messages.create(
                        body=message,
                        from_=self.sms_from,
                        to=number
                    )
                    logger.info(f"✅ SMS Alert sent to {number}")
                except Exception as e:
                    logger.error(f"❌ SMS Failed for {number}: {e}")

# ── Backward Compatibility Helpers ──────────────────────────────────────────

async def process_alert_escalation(incident_id: str, severity: int):
    """Bridge for manual escalation from Alert Router."""
    notifier = NotificationService()
    # Fetch default emergency numbers or use staff numbers
    from .twilio_service import get_staff_phone_numbers
    phones = await get_staff_phone_numbers()
    
    await notifier.dispatch_emergency_alerts(
        incident_id=incident_id,
        incident_type="ESCALATED_EMERGENCY",
        severity=severity,
        location={"lat": 0, "long": 0, "floor": "UNKNOWN"},
        phone_numbers=phones
    )

async def acknowledge_alert(alert_id: str):
    """Placeholder for acknowledging alerts."""
    logger.info(f"Alert {alert_id} acknowledged via NotificationService.")
    return True
