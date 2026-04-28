import firebase_admin
from firebase_admin import credentials, firestore, db
from app.config import settings
import time

# Initialize Firebase Admin SDK
try:
    if settings.FIREBASE_CREDENTIALS_PATH:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_app = firebase_admin.initialize_app(cred, {
            'databaseURL': settings.FIREBASE_DATABASE_URL
        })
    else:
        firebase_app = firebase_admin.initialize_app()
    
    db_firestore = firestore.client()
    db_realtime = db.reference()
    print("Firebase initialized successfully.")
except Exception as e:
    print(f"Warning: Firebase initialization failed: {e}")
    db_firestore = None
    db_realtime = None

class FirebaseService:
    def __init__(self):
        self.db = db_realtime
        self.fs = db_firestore
        self._fs_enabled = db_firestore is not None

    def create_incident(self, incident) -> any:
        if not self.db or not self.fs:
            print("ERROR: Firebase not initialized. Incident not saved.")
            incident.id = f"local_{int(time.time())}"
            return incident

        try:
            data = incident.toJson()
            # Generate key first
            ref = self.db.child('incidents').push()
            incident.id = ref.key
            data['id'] = ref.key
            
            # Push to Realtime DB
            ref.set(data)
            
            # Sync to Firestore (Safe Mode)
            if self._fs_enabled:
                try:
                    self.fs.collection('incidents').document(ref.key).set(data)
                except Exception as fs_err:
                    if "403" in str(fs_err) or "disabled" in str(fs_err).lower():
                        print("CRITICAL: Firestore API is disabled. Switching to RTDB-only mode.")
                        self._fs_enabled = False
                    else:
                        print(f"Firestore Sync Warning: {fs_err}")

            print(f"Firebase: Incident {ref.key} saved successfully (RTDB).")
        except Exception as e:
            print(f"ERROR saving to Firebase: {e}")
            incident.id = f"error_{int(time.time())}"
            
        return incident

    def get_all_active_incidents(self) -> list:
        if not self.db: return []
        try:
            snapshot = self.db.child('incidents').get()
            if not snapshot: return []
            
            incidents = []
            for key, val in snapshot.items():
                if isinstance(val, dict):
                    val['id'] = key
                    incidents.append(val)
            return incidents
        except:
            return []

    def update_incident_status(self, incident_id: str, updates: dict):
        if not self.db or not self.fs: return
        try:
            self.db.child('incidents').child(incident_id).update(updates)
            self.fs.collection('incidents').document(incident_id).update(updates)
        except Exception as e:
            print(f"ERROR updating Firebase: {e}")

def get_firestore_client():
    return db_firestore

def get_realtime_db():
    return db_realtime
