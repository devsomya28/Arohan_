import asyncio
import time
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, incidents, websockets, guest, iot, radio, triage, routing, alert, dashboard, report
from app.routers import photos
from app.config import settings
from app.database import connect_to_mongo, close_mongo_connection
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from app.routers.guest import limiter
from app.services.escalation_service import EscalationService

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(
    title="AAROHAN AI – AOCC Crisis Response API",
    description="Backend for Aarohan Crisis Response System",
    version="2.0.0"
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://chimerical-bombolone-f2d8b8.netlify.app", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 🚨 UNIVERSAL ERROR CATCHER
@app.middleware("http")
async def catch_exceptions_middleware(request, call_next):
    try:
        return await call_next(request)
    except Exception as e:
        logger.error(f"GLOBAL CRASH: {e}", exc_info=True)
        from fastapi.responses import JSONResponse
        return JSONResponse(
            status_code=500,
            content={"detail": f"Aarohan Backend Crash: {str(e)}"}
        )

# Routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(incidents.router, tags=["Incidents"])
app.include_router(guest.router)
app.include_router(photos.router)
app.include_router(iot.router)
app.include_router(radio.router)
app.include_router(triage.router)
app.include_router(routing.router)
app.include_router(alert.router)
app.include_router(dashboard.router)
app.include_router(report.router)
app.include_router(websockets.router, tags=["WebSockets"])

# Serve Flutter Web Frontend
from fastapi.staticfiles import StaticFiles
import os
public_path = os.path.join(os.path.dirname(__file__), "public")
if os.path.exists(public_path):
    app.mount("/", StaticFiles(directory=public_path, html=True), name="public")

@app.on_event("startup")
async def startup_event():
    # Connect to MongoDB
    await connect_to_mongo()
    # Start escalation watchdog
    escalation_service = EscalationService()
    asyncio.create_task(escalation_service.start_monitoring())
    logger.info("AOCC Background Escalation Service: STARTED")

@app.on_event("shutdown")
async def shutdown_event():
    await close_mongo_connection()

@app.get("/", tags=["Root"])
async def read_root():
    """Welcome endpoint."""
    return {
        "status": "online",
        "message": "AAROHAN AI AOCC API is running",
        "version": "2.0.0",
        "documentation": "/docs"
    }

@app.get("/health")
async def health_check():
    """Health check for monitoring."""
    return {"status": "healthy", "timestamp": time.time()}
