from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

import pass_security
from db import models, schemas
from db.database import get_db

app = FastAPI(title="User Service")

security_agent = HTTPBearer()

# Important: Allow local Flutter Web development server to communicate
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For local assessment development, allow everything. Change in production!
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def health_check():
    return {"status": "User Service is OK"}

# REGISTER
@app.post("/api/auth/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user_data: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Check if username already exists
    existing_user = db.query(models.User).filter(models.User.username == user_data.username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username is already registered."
        )
    
    # 2. Hash the user's password securely
    hashed_pwd = pass_security.hash_password(user_data.password)
    
    # 3. Create and save new user record
    new_user = models.User(
        username=user_data.username,
        hashed_password=hashed_pwd,
        name=user_data.name,
        age=user_data.age,
        gender=user_data.gender,
        place_of_living=user_data.place_of_living,
        country_code=user_data.country_code,
        description=user_data.description
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

# LOGIN
@app.post("/api/auth/login", response_model=schemas.TokenResponse)
def login_user(credentials: schemas.UserLogin, db: Session = Depends(get_db)):
    # 1. Fetch user by username
    user = db.query(models.User).filter(models.User.username == credentials.username).first()
    
    # 2. Assert existence and verify password security match
    if not user or not pass_security.verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password."
        )
    
    # 3. Issue signed cryptographic session token token
    token = pass_security.create_access_token(data={"sub": user.username, "id": user.id})
    return {"access_token": token, "token_type": "bearer"}

# get user profile
@app.get("/api/users/profile")
def get_user_profile(
    credentials: HTTPAuthorizationCredentials = Depends(security_agent),
    db: Session = Depends(get_db)
):
    token_payload = pass_security.verify_and_decode_token(credentials)
    user_id = token_payload.get("id")
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User profile not found.")
    
    return {
        "name": user.name,
        "age": user.age,
        "gender": user.gender,
        "place_of_living": user.place_of_living,
        "country_code": user.country_code,
        "description": user.description
    }

# update user profile
@app.put("/api/users/profile")
def update_user_profile(
    profile_data: schemas.ProfileUpdate,
    credentials: HTTPAuthorizationCredentials = Depends(security_agent),
    db: Session = Depends(get_db)
):
    token_payload = pass_security.verify_and_decode_token(credentials)
    user_id = token_payload.get("id")
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User profile not found.")

    # Apply data updates dynamically if values are provided
    update_dict = profile_data.model_dump(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(user, key, value)

    db.commit()
    db.refresh(user)
    return {"status": "Profile successfully updated."}       