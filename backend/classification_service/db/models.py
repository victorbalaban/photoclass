from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from db.database import Base, engine

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    name = Column(String, nullable=False)
    age = Column(Integer, index=True, nullable=False)
    gender = Column(String, index=True, nullable=False)
    place_of_living = Column(String, index=True, nullable=False)
    country_code = Column(String(2), index=True, nullable=False)
    description = Column(String, nullable=True)
    role = Column(String, default="user", nullable=False)
    
    submissions = relationship("Submission", back_populates="owner")

class Submission(Base):
    __tablename__ = "submissions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    image_path = Column(String, nullable=False)
    classification_title = Column(String, nullable=False)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True, nullable=False)

    owner = relationship("User", back_populates="submissions")

# Auto-create tables for the assessment baseline
Base.metadata.create_all(bind=engine)