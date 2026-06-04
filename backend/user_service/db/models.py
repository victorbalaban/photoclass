from sqlalchemy import Column, Integer, String
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
    country_code = Column(String(2), index=True, nullable=False) # Stores ISO alpha-2 code (e.g., 'US', 'CA')
    description = Column(String, nullable=True)

# Auto-create tables for the assessment baseline
Base.metadata.create_all(bind=engine)