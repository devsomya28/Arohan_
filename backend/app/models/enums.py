from enum import Enum

class IncidentType(str, Enum):
    fire = "fire"
    medical = "medical"
    security = "security"
    panic = "panic"

class IncidentSource(str, Enum):
    cctv = "cctv"
    sos = "sos"
    iot = "iot"
    radio = "radio"
    fire_alarm = "fire_alarm"

class IncidentStatus(str, Enum):
    detected = "detected"
    assigned = "assigned"
    resolved = "resolved"
