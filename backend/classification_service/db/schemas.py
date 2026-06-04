from datetime import datetime
from pydantic import BaseModel

class SubmissionResponse(BaseModel):
    id: int
    user_id: int
    classification_title: str
    timestamp: datetime
    image_url: str

    class Config:
        from_attributes = True  # Allows Pydantic to read SQLAlchemy database models

class AdminSubmissionResponse(BaseModel):
    id: int
    classification_title: str
    timestamp: datetime
    user_name: str
    user_age: int
    user_gender: str
    user_country: str
    image_url: str

    class Config:
        from_attributes = True