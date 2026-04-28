from pydantic_settings import BaseSettings
from typing import Optional
from dotenv import load_dotenv
import os

load_dotenv()

class Settings(BaseSettings):
    PROJECT_NAME: str = "Crisis Response System"
    SECRET_KEY: str = "super-secret-key-replace-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # MongoDB Atlas
    MONGODB_URL: Optional[str] = "mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority"
    MONGODB_DB_NAME: str = "arohan_db"

    # Firebase settings
    FIREBASE_CREDENTIALS_PATH: Optional[str] = "serviceAccountKey.json"
    FIREBASE_DATABASE_URL: Optional[str] = "https://arohan-2cc58-default-rtdb.firebaseio.com/"
    GOOGLE_CLOUD_PROJECT: Optional[str] = "arohan-2cc58"

    # Google Gemini
    GEMINI_API_KEY: Optional[str] = None

    # Twilio
    TWILIO_ACCOUNT_SID: Optional[str] = None
    TWILIO_AUTH_TOKEN: Optional[str] = None
    TWILIO_FROM_NUMBER: Optional[str] = None
    TWILIO_WHATSAPP_FROM: Optional[str] = None
    TEST_PHONE_NUMBER: Optional[str] = None

    class Config:
        env_file = ".env"

settings = Settings()
