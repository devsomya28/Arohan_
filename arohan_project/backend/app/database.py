"""
MongoDB Database Connection using Motor (async driver).
This module provides the database connection and collection helpers.
"""
from motor.motor_asyncio import AsyncIOMotorClient
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# Global client instance
_client: AsyncIOMotorClient = None
_db = None

async def connect_to_mongo():
    """Initialize MongoDB connection on startup."""
    global _client, _db
    try:
        _client = AsyncIOMotorClient(settings.MONGODB_URL, serverSelectionTimeoutMS=10000)
        _db = _client[settings.MONGODB_DB_NAME]
        # Test connection
        await _client.admin.command('ping')
        logger.info(f"MongoDB Connected: {settings.MONGODB_DB_NAME}")
    except Exception as e:
        logger.error(f"MongoDB Connection FAILED: {e}")
        logger.warning("Running without MongoDB - some features will be unavailable")
        _client = None
        _db = None

async def close_mongo_connection():
    """Close MongoDB connection on shutdown."""
    global _client
    if _client:
        _client.close()
        logger.info("MongoDB connection closed.")

def get_database():
    """Returns the database instance. Can be None if connection failed."""
    return _db

def get_collection(name: str):
    """Returns a MongoDB collection by name."""
    if _db is None:
        return None
    return _db[name]
