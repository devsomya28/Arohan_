"""
Twilio Service for SMS and WhatsApp emergency alerts.
Add your credentials to the .env file to activate.
"""
import logging
from typing import List
from app.config import settings

logger = logging.getLogger(__name__)

def _get_client():
    """Returns a Twilio client if credentials are set, else None."""
    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
        logger.warning("Twilio credentials not set. Messages will be logged only.")
        return None
    try:
        from twilio.rest import Client
        return Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
    except ImportError:
        logger.error("Twilio package not installed. Run: pip install twilio")
        return None
    except Exception as e:
        logger.error(f"Twilio client init failed: {e}")
        return None

async def send_emergency_sms(phone_numbers: List[str], message: str):
    """
    Sends an emergency SMS to a list of phone numbers.
    phone_numbers: list of E.164 formatted numbers e.g. ["+919876543210"]
    """
    client = _get_client()
    if not client or not settings.TWILIO_FROM_NUMBER:
        logger.info(f"[SMS MOCK] Would send to {phone_numbers}: {message}")
        return

    for number in phone_numbers:
        try:
            if settings.TWILIO_FROM_NUMBER.startswith("MG"):
                msg = client.messages.create(
                    body=message,
                    messaging_service_sid=settings.TWILIO_FROM_NUMBER,
                    to=number
                )
            else:
                msg = client.messages.create(
                    body=message,
                    from_=settings.TWILIO_FROM_NUMBER,
                    to=number
                )
            logger.info(f"✅ SMS SUCCESS: Sent to {number} (SID: {msg.sid})")
        except Exception as e:
            logger.error(f"❌ SMS FAILED: To {number}. Error: {e}")

async def send_emergency_whatsapp(phone_numbers: List[str], message: str):
    """
    Sends emergency WhatsApp message via Twilio.
    phone_numbers: list of E.164 formatted numbers
    """
    client = _get_client()
    if not client or not settings.TWILIO_WHATSAPP_FROM:
        logger.info(f"[WHATSAPP MOCK] Would send to {phone_numbers}: {message}")
        return

    from_num = settings.TWILIO_WHATSAPP_FROM
    if not from_num.startswith('whatsapp:'):
        from_num = f"whatsapp:{from_num}"

    for number in phone_numbers:
        try:
            to_num = number if number.startswith('whatsapp:') else f"whatsapp:{number}"
            msg = client.messages.create(
                body=message,
                from_=from_num,
                to=to_num
            )
            logger.info(f"✅ WHATSAPP SUCCESS: Sent to {number} (SID: {msg.sid})")
        except Exception as e:
            logger.error(f"❌ WHATSAPP FAILED: To {number}. Error: {e}")

async def get_staff_phone_numbers() -> List[str]:
    """
    Fetches on-duty staff phone numbers from MongoDB.
    Returns a list of phone numbers for active staff.
    """
    try:
        from app.database import get_collection
        collection = get_collection("staff")
        if collection is None:
            logger.warning("MongoDB not connected - using fallback staff numbers")
            return []  # Return empty list; add hardcoded fallbacks if needed
        
        # Query all active staff with phone numbers
        cursor = collection.find({"is_on_duty": True, "phone": {"$exists": True}})
        staff_list = await cursor.to_list(length=100)
        phones = [s["phone"] for s in staff_list if s.get("phone")]
        
        if not phones and settings.TEST_PHONE_NUMBER:
            logger.info("No active staff found in MongoDB. Using TEST_PHONE_NUMBER from .env.")
            return [settings.TEST_PHONE_NUMBER]
            
        logger.info(f"Fetched {len(phones)} on-duty staff numbers from MongoDB")
        return phones
    except Exception as e:
        logger.error(f"Failed to fetch staff numbers: {e}")
        if settings.TEST_PHONE_NUMBER:
            return [settings.TEST_PHONE_NUMBER]
        return []

async def dispatch_incident_alert(incident_id: str, incident_type: str, severity: int, location: dict, custom_phone: any = None):
    """
    Main function: fetches staff numbers from DB and sends alerts.
    Called by the Orchestrator when a new incident is created.
    """
    if custom_phone:
        if isinstance(custom_phone, list):
            logger.info(f"Using multiple custom guardian phone numbers: {custom_phone}")
            phones = custom_phone
        else:
            logger.info(f"Using custom guardian phone number: {custom_phone}")
            phones = [custom_phone]
    else:
        phones = await get_staff_phone_numbers()
    
    lat = location.get('lat')
    lng = location.get('long')
    maps_link = f"https://www.google.com/maps/search/?api=1&query={lat},{lng}" if lat and lng else "Location shared in app."

    message = (
        f"🚨 AAROHAN AI SOS - #{incident_id}\n"
        f"TYPE: {incident_type.upper()} | SEV: {severity}/10\n"
        f"📍 TRACK ME: {maps_link}\n"
        f"Floor: {location.get('floor', 'N/A')}\n"
        f"RESPOND IMMEDIATELY"
    )
    
    if phones:
        await send_emergency_sms(phones, message)
        await send_emergency_whatsapp(phones, message)
    else:
        logger.info(f"[ALERT] {message}")
        logger.info("No staff phone numbers found. Add staff to MongoDB 'staff' collection with 'phone' and 'is_on_duty' fields.")
