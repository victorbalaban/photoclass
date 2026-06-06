import os
import bcrypt
import jwt
from datetime import datetime, timedelta, timezone

# Mocked for now. In production, load these from secure env variables!
SECRET_KEY = os.getenv("JWT_SECRET", "super-secret-assessment-token-key-99123")
ALGORITHM = "HS256"

def hash_password(password: str) -> str:
    password_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password_bytes, salt).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=60)
    
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_and_decode_token(credentials = None) -> dict:
    from fastapi import HTTPException, status, Security
    from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

    # Fallback to local security instantiation if FastAPI dependencies evaluate
    security_agent = HTTPBearer()
    
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization headers parameters."
        )
        
    try:
        token = credentials.credentials
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload  # Returns the un-falsifiable dict map: {"sub": username, "id": user_id, "exp": ...}
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session has expired or authentication credentials are invalid."
        )    