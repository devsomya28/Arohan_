import math
from typing import List, Optional, Tuple
import logging
from app.models.incident import Location, IncidentType
from app.models.responder import Responder, ResponderRole
from app.database import get_collection
from app.services.twilio_service import send_emergency_sms

logger = logging.getLogger(__name__)

# Mock live database of responders
mock_responders = [
    Responder(id="R001", role=ResponderRole.fire_team, live_location=Location(lat=40.7128, long=-74.0060, floor=1), availability=True),
    Responder(id="R002", role=ResponderRole.medic, live_location=Location(lat=40.7138, long=-74.0050, floor=2), availability=True),
    Responder(id="R003", role=ResponderRole.guard, live_location=Location(lat=40.7118, long=-74.0070, floor=1), availability=True),
    Responder(id="R004", role=ResponderRole.medic, live_location=Location(lat=40.7150, long=-74.0020, floor=5), availability=True),
    Responder(id="R005", role=ResponderRole.fire_team, live_location=Location(lat=40.7100, long=-74.0090, floor=1), availability=False),
]

def haversine_distance(loc1: Location, loc2: Location) -> float:
    """
    Calculate the great circle distance in kilometers between two points 
    on the earth (specified in decimal degrees) using Haversine formula.
    """
    # Convert decimal degrees to radians 
    lat1, lon1, lat2, lon2 = map(math.radians, [loc1.lat, loc1.long, loc2.lat, loc2.long])

    # Haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a)) 
    r = 6371 # Radius of earth in kilometers
    return c * r

def get_required_role(incident_type: str) -> ResponderRole:
    """
    Map incident type to the required responder role.
    """
    incident_type = incident_type.lower()
    if incident_type == "fire":
        return ResponderRole.fire_team
    elif incident_type in ["medical", "injury"]:
        return ResponderRole.medic
    elif incident_type in ["security", "panic"]:
        return ResponderRole.guard
    else:
        return ResponderRole.general

def calculate_eta(distance_km: float) -> int:
    """
    Calculate rough ETA in minutes.
    Assuming average walking/running speed in a facility is ~5 km/h.
    ETA (mins) = (distance_km / speed_km_h) * 60
    """
    speed_km_h = 5.0
    eta_mins = (distance_km / speed_km_h) * 60
    # Add a minimum 1 minute response time
    return max(1, math.ceil(eta_mins))

async def find_nearest_responder_live(incident_type: str, incident_location: Location) -> Tuple[Optional[dict], float, int]:
    """
    Finds the nearest on-duty staff from MongoDB using Haversine distance.
    """
    collection = get_collection("staff")
    if collection is None:
        return None, 0.0, 0

    # Fetch on-duty staff
    cursor = collection.find({"is_on_duty": True})
    staff_list = await cursor.to_list(length=100)

    if not staff_list:
        return None, 0.0, 0

    nearest_staff = None
    min_distance = float('inf')

    for staff in staff_list:
        staff_loc = Location(
            lat=staff['location']['latitude'], 
            long=staff['location']['longitude'],
            floor=staff.get('floor', 1)
        )
        
        dist = haversine_distance(incident_location, staff_loc)
        
        # Floor penalty
        if incident_location.floor:
            floor_diff = abs(staff_loc.floor - incident_location.floor)
            dist += floor_diff * 0.05 

        if dist < min_distance:
            min_distance = dist
            nearest_staff = staff

    eta = calculate_eta(min_distance)
    return nearest_staff, min_distance, eta

async def dispatch_to_closest(incident_id: str, guest_phone: str, incident_location: Location, incident_type: str):
    """
    Finds the closest responder and sends a direct Twilio dispatch.
    """
    staff, dist, eta = await find_nearest_responder_live(incident_type, incident_location)
    
    if staff and "phone" in staff:
        maps_link = f"https://www.google.com/maps/search/?api=1&query={incident_location.lat},{incident_location.long}"
        message = (
            f"🚀 EMERGENCY DISPATCH: You are the CLOSEST responder ({int(dist*1000)}m away).\n"
            f"GUEST PHONE: {guest_phone}\n"
            f"MAP: {maps_link}\n"
            f"ETA: {eta} mins. RESPOND NOW!"
        )
        await send_emergency_sms([staff['phone']], message)
        logger.info(f"[DISPATCH] Sent to {staff['name']} ({staff['phone']})")
    else:
        logger.warning("[DISPATCH] No staff found within range for Twilio alert.")
