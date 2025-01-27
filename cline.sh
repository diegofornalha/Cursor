#!/bin/zsh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configurações
WORKSPACE_DIR="$PWD"
CACHE_DIR="$HOME/.cache/cline"
LOG_FILE="$HOME/.cache/cline/cline.log"
VENV_DIR="venv"

# Cria diretórios necessários
mkdir -p "$CACHE_DIR"
touch "$LOG_FILE"

# Funções de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Ativa ambiente virtual
setup_venv() {
    if [ ! -d "$VENV_DIR" ]; then
        printf "${BLUE}Criando ambiente virtual...${NC}\n"
        python3 -m venv "$VENV_DIR"
    fi
    source "$VENV_DIR/bin/activate"
    pip install -r requirements.txt
    log "Ambiente virtual ativado e dependências instaladas"
}

# Funções FastAPI
create_endpoint() {
    local resource=$1
    if [ -z "$resource" ]; then
        printf "${YELLOW}Digite o nome do recurso (ex: users): ${NC}"
        read resource
    fi
    
    # Cria arquivo de rotas
    local router_file="${resource}_router.py"
    printf "${BLUE}Criando endpoint para $resource...${NC}\n"
    
    cat > "$router_file" << EOL
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

router = APIRouter()

@router.get("/${resource}/", response_model=List[${resource^}])
async def list_${resource}(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    """Lista todos os ${resource} com paginação"""
    return db.query(${resource^}Model).offset(skip).limit(limit).all()

@router.post("/${resource}/", response_model=${resource^}, status_code=201)
async def create_${resource}(item: ${resource^}Create, db: Session = Depends(get_db)):
    """Cria um novo ${resource}"""
    db_item = ${resource^}Model(**item.dict())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item
EOL
    
    printf "${GREEN}✓ Endpoint criado em $router_file${NC}\n"
    log "Criado endpoint: $router_file"
}

create_model() {
    local model=$1
    if [ -z "$model" ]; then
        printf "${YELLOW}Digite o nome do modelo: ${NC}"
        read model
    fi
    
    local model_file="models.py"
    printf "${BLUE}Criando/atualizando modelo $model...${NC}\n"
    
    # Verifica se o arquivo já existe
    if [ ! -f "$model_file" ]; then
        cat > "$model_file" << EOL
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()
EOL
    fi
    
    # Adiciona novo modelo
    cat >> "$model_file" << EOL

class ${model^}Model(Base):
    __tablename__ = "${model}s"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    class Config:
        orm_mode = True
EOL
    
    printf "${GREEN}✓ Modelo adicionado em $model_file${NC}\n"
    log "Criado/atualizado modelo: $model"
}

create_test() {
    local resource=$1
    if [ -z "$resource" ]; then
        printf "${YELLOW}Digite o nome do recurso para testar: ${NC}"
        read resource
    fi
    
    local test_file="test_${resource}.py"
    printf "${BLUE}Gerando testes para $resource...${NC}\n"
    
    cat > "$test_file" << EOL
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .models import Base, ${resource^}Model
from .${resource}_router import router

# Configuração do banco de teste
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(bind=engine)

@pytest.fixture
def test_db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

def test_create_${resource}(test_db):
    """Testa criação de ${resource}"""
    response = client.post(
        "/${resource}s/",
        json={"name": "Test ${resource^}"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test ${resource^}"
EOL
    
    printf "${GREEN}✓ Testes gerados em $test_file${NC}\n"
    log "Gerados testes: $test_file"
}

run_tests() {
    printf "${BLUE}Executando testes...${NC}\n"
    pytest -v
    log "Executados testes"
}

generate_docs() {
    printf "${BLUE}Gerando documentação...${NC}\n"
    
    # Cria diretório docs se não existir
    mkdir -p docs
    
    # Gera documentação para cada arquivo Python
    for file in *.py; do
        if [ -f "$file" ]; then
            local doc_file="docs/${file%.*}.md"
            echo "# Documentação de $file" > "$doc_file"
            echo "\n## Funções e Classes\n" >> "$doc_file"
            grep -E '^[[:space:]]*(def|class)[[:space:]]+.*:' "$file" | sed 's/^[[:space:]]*\(def\|class\)[[:space:]]\+/- /' >> "$doc_file"
        fi
    done
    
    printf "${GREEN}✓ Documentação gerada em ./docs/${NC}\n"
    log "Gerada documentação"
}

run_server() {
    printf "${BLUE}Iniciando servidor FastAPI...${NC}\n"
    uvicorn main:app --reload
    log "Iniciado servidor"
}

# Menu de ajuda
show_help() {
    printf "${BLUE}=== Cline Python CLI ===${NC}\n"
    printf "setup              - Configura ambiente virtual\n"
    printf "endpoint [nome]    - Cria novo endpoint\n"
    printf "model [nome]       - Cria/atualiza modelo\n"
    printf "test [recurso]     - Gera testes\n"
    printf "run-tests         - Executa todos os testes\n"
    printf "docs              - Gera documentação\n"
    printf "server            - Inicia servidor FastAPI\n"
    printf "help              - Mostra esta ajuda\n"
    printf "exit              - Sai do Cline\n"
}

# Loop principal
printf "${GREEN}Cline Python CLI iniciado. Digite 'help' para ver os comandos.${NC}\n"

while true; do
    printf "${BLUE}cline>${NC} "
    read -r cmd name
    
    case $cmd in
        "setup") setup_venv ;;
        "endpoint") create_endpoint "$name" ;;
        "model") create_model "$name" ;;
        "test") create_test "$name" ;;
        "run-tests") run_tests ;;
        "docs") generate_docs ;;
        "server") run_server ;;
        "help") show_help ;;
        "exit") break ;;
        *) 
            if [ -n "$cmd" ]; then
                printf "${RED}Comando inválido. Digite 'help' para ver os comandos.${NC}\n"
            fi
            ;;
    esac
done

printf "${GREEN}Cline Python CLI finalizado.${NC}\n" 