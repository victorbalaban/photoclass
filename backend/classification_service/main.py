import os
import shutil
import jwt
from typing import List, Optional
from datetime import datetime
from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Security, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from db import models, schemas
from db.database import get_db

# Core Security Shared Secrets Configuration
SECRET_KEY = "super-secret-assessment-token-key-99123"
ALGORITHM = "HS256"
security_agent = HTTPBearer()

# Shared Volume Storage Target Directory
STORAGE_DIR = "/app/shared_storage/submissions"
os.makedirs(STORAGE_DIR, exist_ok=True)

app = FastAPI(title="Classification Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# This maps physical container directory directly to http://localhost:8001/static/
app.mount("/static", StaticFiles(directory=STORAGE_DIR), name="static")

def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security_agent)) -> dict:
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session token.")

@app.get("/")
def health_check():
    return {"status": "Classification engine is online and running on port 8001"}


# endpoint for photo upload and classification
@app.post("/api/submissions/upload", response_model=schemas.SubmissionResponse, status_code=status.HTTP_201_CREATED)
def upload_and_classify_photo(
    file: UploadFile = File(...),
    user_token: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File asset must be a valid image container.")

    user_id = user_token.get("id")
    timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    filename = f"{user_id}_{timestamp_str}_{file.filename}"
    file_path = os.path.join(STORAGE_DIR, filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    detected_classification = f"Classified Object Focus ({file.filename})"

    new_submission = models.Submission(
        user_id=user_id,
        image_path=file_path,
        classification_title=detected_classification
    )
    db.add(new_submission)
    db.commit()
    db.refresh(new_submission)
    
    new_submission.image_url = f"http://localhost:8001/static/{filename}"
    return new_submission


# get user's own submissions with public URLs for images
@app.get("/api/submissions/me", response_model=List[schemas.SubmissionResponse])
def get_my_submissions(user_token: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    user_id = user_token.get("id")
    results = db.query(models.Submission).filter(models.Submission.user_id == user_id).order_by(models.Submission.timestamp.desc()).all()
    
    # Loop over database objects and construct public URLs dynamically
    for s in results:
        clean_filename = os.path.basename(s.image_path)
        s.image_url = f"http://localhost:8001/static/{clean_filename}"
        
    return results


# admin check
def require_admin(user_token: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    user_id = user_token.get("id")
    user = db.query(models.User).filter(models.User.id == user_id).first()
    
    if not user or user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Administrative privileges required."
        )
    return user

# admin endpoint to retrieve all submissions with optional filters for user demographics and location
@app.get("/api/submissions/admin", response_model=List[schemas.AdminSubmissionResponse])
def admin_get_all_submissions(
    age: Optional[int] = Query(None),
    gender: Optional[str] = Query(None),
    location: Optional[str] = Query(None),
    country_code: Optional[str] = Query(None),
    user_token: dict = Depends(require_admin),
    db: Session = Depends(get_db)
):
    query = db.query(models.Submission).join(models.User, models.Submission.user_id == models.User.id)
    
    if age is not None:
        query = query.filter(models.User.age == age)
    if gender:
        query = query.filter(models.User.gender == gender)
    if location:
        query = query.filter(models.User.place_of_living.ilike(f"%{location}%"))
    if country_code:
        query = query.filter(models.User.country_code == country_code.upper())
        
    results = query.order_by(models.Submission.timestamp.desc()).all()
    
    return [
        {
            "id": s.id,
            "classification_title": s.classification_title,
            "timestamp": s.timestamp,
            "user_name": s.owner.name,
            "user_age": s.owner.age,
            "user_gender": s.owner.gender,
            "user_country": s.owner.country_code,
            "image_url": f"http://localhost:8001/static/{os.path.basename(s.image_path)}"
        } for s in results
    ]