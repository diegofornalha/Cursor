from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, EmailStr
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

# Modelo Pydantic para validação
class UserBase(BaseModel):
    name: str
    email: EmailStr
    
class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None

class User(UserBase):
    id: int
    created_at: datetime
    
    class Config:
        orm_mode = True

# Router FastAPI
router = FastAPI()

# Endpoints
@router.get("/users/", response_model=List[User])
async def list_users(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    """
    Lista todos os usuários com paginação
    """
    users = db.query(UserModel).offset(skip).limit(limit).all()
    return users

@router.post("/users/", response_model=User, status_code=201)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    """
    Cria um novo usuário
    """
    # Verifica se email já existe
    if db.query(UserModel).filter(UserModel.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email já registrado")
    
    # Cria o usuário
    db_user = UserModel(
        name=user.name,
        email=user.email,
        password=hash_password(user.password)  # Função para hash da senha
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.get("/users/{user_id}", response_model=User)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    """
    Retorna um usuário específico
    """
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return user

@router.put("/users/{user_id}", response_model=User)
async def update_user(user_id: int, user: UserUpdate, db: Session = Depends(get_db)):
    """
    Atualiza um usuário
    """
    db_user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    # Atualiza apenas os campos fornecidos
    update_data = user.dict(exclude_unset=True)
    if "password" in update_data:
        update_data["password"] = hash_password(update_data["password"])
    
    for key, value in update_data.items():
        setattr(db_user, key, value)
    
    db.commit()
    db.refresh(db_user)
    return db_user

@router.delete("/users/{user_id}", status_code=204)
async def delete_user(user_id: int, db: Session = Depends(get_db)):
    """
    Remove um usuário
    """
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    db.delete(user)
    db.commit()
    return None 