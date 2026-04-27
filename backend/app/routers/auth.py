"""
Auth Router — JWT login, signup backed by MongoDB.
"""
import logging
import asyncio
from datetime import timedelta
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
from app.config import settings
from app.models.user import Token, User
from app.utils.security import verify_password, create_access_token, hash_password
from app.dependencies import get_current_active_user
from app.database import get_collection

logger = logging.getLogger(__name__)
router = APIRouter()

class SignupRequest(BaseModel):
    username: str
    password: str
    full_name: Optional[str] = ""
    email: Optional[str] = ""
    role: Optional[str] = "staff"  # guest | staff | admin

# ── Fallback in-memory users (High Resilience Mode) ──
_FALLBACK_USERS = {
    "staff1": {
        "username": "staff1",
        "full_name": "Default Staff",
        "email": "staff@arohan.com",
        "hashed_password": "$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW",  # "secret"
        "disabled": False,
        "role": "staff",
    },
    "guest1": {
        "username": "guest1",
        "full_name": "Demo Guest",
        "email": "guest@arohan.com",
        "hashed_password": "$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW",  # "secret"
        "disabled": False,
        "role": "guest",
    },
    "admin": {
        "username": "admin",
        "full_name": "Admin User",
        "email": "admin@arohan.com",
        "hashed_password": "$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW",  # "secret"
        "disabled": False,
        "role": "admin",
    }
}

async def _find_user_in_mongo(username: str) -> Optional[dict]:
    """Looks up a user in MongoDB users collection."""
    try:
        col = get_collection("users")
        if col is None:
            return None
        # Strict 5s timeout for DB lookup
        return await asyncio.wait_for(col.find_one({"username": username}), timeout=5.0)
    except asyncio.TimeoutError:
        logger.warning(f"MongoDB lookup TIMEOUT for {username}")
        return None
    except Exception as e:
        logger.error(f"MongoDB user lookup failed: {e}")
        return None

@router.post("/token", response_model=Token)
async def login_for_access_token(form_data: Annotated[OAuth2PasswordRequestForm, Depends()]):
    """
    OAuth2 compatible login. Checks MongoDB first, then in-memory fallback.
    Flutter should POST to /auth/token with username and password as form fields.
    Returns a JWT access_token.
    """
    # 🎯 FIX: Define username FIRST, then log it.
    username = form_data.username.strip()
    logger.info(f"Login Attempt: {username}")
    
    # Try MongoDB first
    logger.info(f"Auth: Searching MongoDB for '{username}'...")
    user_dict = await _find_user_in_mongo(username)
    
    # Fall back to in-memory users
    if user_dict is None:
        logger.info(f"Auth: User '{username}' not in Mongo. Checking fallback...")
        user_dict = _FALLBACK_USERS.get(username)
    
    if not user_dict:
        logger.warning(f"Auth: Login failed - User '{username}' not found.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    logger.info(f"Auth: User found. Verifying password...")
    if not verify_password(form_data.password, user_dict["hashed_password"]):
        logger.warning(f"Auth: Login failed - Invalid password for '{username}'.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    logger.info(f"Auth: Password verified. Generating token...")
    
    if user_dict.get("disabled"):
        raise HTTPException(status_code=400, detail="Account is disabled")
    
    access_token = create_access_token(
        data={"sub": user_dict["username"], "role": user_dict.get("role", "staff")},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user_dict.get("role", "staff"),
        "username": user_dict["username"],
    }

@router.post("/signup", status_code=201)
async def signup(req: SignupRequest):
    """
    Creates a new user in MongoDB.
    Flutter can call POST /auth/signup with JSON body.
    """
    col = get_collection("users")
    if col is None:
        logger.warning(f"Database UNAVAILABLE. Saving {req.username} to Mock Storage.")
        _FALLBACK_USERS[req.username] = {
            "username": req.username,
            "full_name": req.full_name,
            "email": req.email,
            "hashed_password": hash_password(req.password),
            "disabled": False,
            "role": req.role,
        }
        return {"message": "Account created successfully (Mock Mode)", "username": req.username}
    
    # Check for existing user
    try:
        existing = await asyncio.wait_for(col.find_one({"username": req.username}), timeout=5.0)
        if existing:
            raise HTTPException(status_code=409, detail="Username already exists")
        
        user_doc = {
            "username": req.username,
            "full_name": req.full_name,
            "email": req.email,
            "hashed_password": hash_password(req.password),
            "disabled": False,
            "role": req.role,
        }
        
        await asyncio.wait_for(col.insert_one(user_doc), timeout=5.0)
        logger.info(f"New user created: {req.username} ({req.role})")
        return {"message": "Account created successfully", "username": req.username}
    except (Exception, asyncio.TimeoutError) as e:
        logger.error(f"Signup DB Error/Timeout: {e}. Falling back to Mock Storage.")
        _FALLBACK_USERS[req.username] = {
            "username": req.username,
            "full_name": req.full_name,
            "email": req.email,
            "hashed_password": hash_password(req.password),
            "disabled": False,
            "role": req.role,
        }
        return {"message": "Account created successfully (Fallback Mode)", "username": req.username}

@router.get("/users/me", response_model=User)
async def read_users_me(current_user: Annotated[User, Depends(get_current_active_user)]):
    return current_user
