from pydantic import BaseModel, Field

class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6)
    name: str = Field(..., min_length=1, max_length=100)
    age: int = Field(..., ge=0, le=125)
    gender: str = Field(..., min_length=1, max_length=30)
    place_of_living: str = Field(..., min_length=1, max_length=150)
    country_code: str = Field(..., min_length=2, max_length=2) # Enforces strict ISO code size
    description: str | None = Field(None, max_length=1000)

class UserLogin(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6)    

class UserResponse(BaseModel):
    id: int
    username: str
    name: str
    country_code: str

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str