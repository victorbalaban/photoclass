import os
import random
import shutil
import jwt
import uuid
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


# Photo upload and classification
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
    
    _, original_ext = os.path.splitext(file.filename)
    clean_ext = original_ext.lower()

    unique_suffix = uuid.uuid4().hex[:6]
    
    filename = f"sub_{user_id}_{timestamp_str}_{unique_suffix}{clean_ext}"
    file_path = os.path.join(STORAGE_DIR, filename)
    
    # Handle file upload IO bytes stream storage mapping
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Run classification helper (mocked for now)
    detected_classification = run_image_classification(file_path)

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

# Placeholder function for image classification logic - to be replaced with actual ML model inference
def run_image_classification(file_path: str) -> str:
    """
    Analyzes an image file path and evaluates its visual contents.
    Currently mocked with a randomized tag router, prepared for direct ML model insertion.
    """
    classification_options = [
        "Nature Photo",
        "Portrait Canvas",
        "Cityscape Landscape",
        "Botanical Layout",
        "Sci-Fi Motif",
        "Abstract Graphic Composition",
        "Wildlife Photography"
    ]
    
    # Returns a random item from our target list array
    return random.choice(classification_options)

# Get user's own submissions with public URLs for images
@app.get("/api/submissions/me", response_model=List[schemas.SubmissionResponse])
def get_my_submissions(user_token: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    user_id = user_token.get("id")
    results = db.query(models.Submission).filter(models.Submission.user_id == user_id).order_by(models.Submission.timestamp.desc()).all()
    
    # Loop over database objects and construct public URLs dynamically
    for s in results:
        clean_filename = os.path.basename(s.image_path)
        s.image_url = f"http://localhost:8001/static/{clean_filename}"
        
    return results


# Admin check
def require_admin(user_token: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    user_id = user_token.get("id")
    user = db.query(models.User).filter(models.User.id == user_id).first()
    
    if not user or user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Administrative privileges required."
        )
    return user

# Admin endpoint to retrieve all submissions with optional filters for user demographics and location
@app.get("/api/submissions/admin", response_model=List[schemas.AdminSubmissionResponse])
def admin_get_all_submissions(
    age: Optional[int] = Query(None),
    gender: Optional[str] = Query(None),
    place_of_living: Optional[str] = Query(None),
    country_code: Optional[str] = Query(None),
    user_token: dict = Depends(require_admin),
    db: Session = Depends(get_db)
):
    query = db.query(models.Submission).join(models.User, models.Submission.user_id == models.User.id)
    
    if age is not None:
        query = query.filter(models.User.age == age)
    if gender:
        query = query.filter(models.User.gender == gender)
    if place_of_living:
        query = query.filter(models.User.place_of_living.ilike(f"%{place_of_living}%"))
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
            "user_place_of_living": s.owner.place_of_living,
            "user_country": s.owner.country_code,
            "image_url": f"http://localhost:8001/static/{os.path.basename(s.image_path)}"
        } for s in results
    ]


# Endpoint for users to delete their own submitted photo
@app.delete("/api/submissions/{submission_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_submission(
    submission_id: int,
    user_token: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_id = user_token.get("id")
    
    # Fetch the submission from the database instance
    submission = db.query(models.Submission).filter(models.Submission.id == submission_id).first()
    
    if not submission:
        raise HTTPException(status_code=404, detail="Requested submission record does not exist.")
        
    # SECURITY CHECK: Verify the token identity matches the resource owner
    if submission.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Access Denied: You do not own this resource container."
        )
        
    # Storage: Wiping the file from the persistent Docker folder volume
    if os.path.exists(submission.image_path):
        try:
            os.remove(submission.image_path)
        except Exception as file_error:
            # Logs disk warnings without breaking execution flow if file was already moved
            print(f"--- DISK WARNING: Failed to remove physical asset file: {file_error} ---", flush=True)

    # Database: Delete the entry row
    db.delete(submission)
    db.commit()
    
    return None