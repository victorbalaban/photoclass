from sqlalchemy import Column, Integer, String
from db.database import Base, engine

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)

# Auto-create tables for the assessment baseline
Base.metadata.create_all(bind=engine)