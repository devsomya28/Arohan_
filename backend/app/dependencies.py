from typing import Annotated, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from app.config import settings
from app.models.user import TokenData, User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")

async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception

    # Try to find user in MongoDB
    try:
        from app.database import get_collection
        col = get_collection("users")
        user_dict = None
        if col is not None:
            user_dict = await col.find_one({"username": token_data.username})
        if user_dict is None:
            # Fallback to in-memory
            from app.routers.auth import _FALLBACK_USERS
            user_dict = _FALLBACK_USERS.get(token_data.username)
        if user_dict is None:
            raise credentials_exception
        return User(**{k: v for k, v in user_dict.items() if k in User.model_fields})
    except HTTPException:
        raise
    except Exception as e:
        raise credentials_exception

async def get_current_active_user(current_user: Annotated[User, Depends(get_current_user)]):
    if current_user.disabled:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

# Kept for backwards compat
fake_users_db = {}
