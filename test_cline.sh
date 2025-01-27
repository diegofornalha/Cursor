#!/bin/zsh

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "${BLUE}Iniciando setup do ambiente Python...${NC}"

# Criar e ativar ambiente virtual
python3 -m venv venv
source venv/bin/activate

# Atualizar pip
python -m pip install --upgrade pip

# Instalar dependências (escapando colchetes para o zsh)
pip install 'fastapi' 'uvicorn' 'sqlalchemy' 'pydantic' 'pytest' 'httpx' 'python-jose[cryptography]' 'passlib[bcrypt]' 'python-multipart'

# Criar estrutura básica do projeto
mkdir -p app/api app/models app/tests

# Criar arquivo de modelo
cat > app/models/user.py << EOF
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
EOF

# Criar arquivo de endpoint
cat > app/api/users.py << EOF
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
EOF

# Criar arquivo de testes
cat > app/tests/test_users.py << EOF
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_user():
    response = client.post(
        "/users/",
        json={"name": "Test User", "email": "test@example.com", "password": "secret"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Test User"
    assert data["email"] == "test@example.com"
    assert "id" in data
EOF

# Criar arquivo principal
cat > app/main.py << EOF
from fastapi import FastAPI
from app.api.users import router as users_router

app = FastAPI(title="Cline API")

app.include_router(users_router)
EOF

echo "${GREEN}Setup concluído! Você pode iniciar o servidor com:${NC}"
echo "uvicorn app.main:app --reload" 