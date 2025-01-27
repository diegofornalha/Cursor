from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import List

router = APIRouter()

class UserBase(BaseModel):
    name: str
    email: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

@router.post("/users/", response_model=User)
async def create_user(user: UserCreate):
    return {"id": 1, **user.dict(), "created_at": datetime.utcnow()}

@router.get("/users/", response_model=List[User])
async def list_users():
    return []
