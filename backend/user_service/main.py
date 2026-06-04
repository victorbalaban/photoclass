from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

import pass_security
from db import models, schemas
from db.database import get_db

app = FastAPI(title="User Service")

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