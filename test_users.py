import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from .models import Base, UserModel
from .users_router import router, get_db

# Configuração do banco de dados de teste
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Fixture para criar/limpar o banco de dados
@pytest.fixture
def test_db():
    Base.metadata.create_all(bind=engine)
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

# Fixture para o cliente de teste
@pytest.fixture
def client(test_db):
    def override_get_db():
        try:
            yield test_db
        finally:
            test_db.close()
    
    router.dependency_overrides[get_db] = override_get_db
    return TestClient(router)

def test_create_user(client):
    response = client.post(
        "/users/",
        json={"name": "Test User", "email": "test@example.com", "password": "password123"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test User"
    assert data["email"] == "test@example.com"
    assert "password" not in data

def test_create_duplicate_user(client):
    # Cria primeiro usuário
    client.post(
        "/users/",
        json={"name": "Test User", "email": "test@example.com", "password": "password123"}
    )
    
    # Tenta criar usuário com mesmo email
    response = client.post(
        "/users/",
        json={"name": "Another User", "email": "test@example.com", "password": "password456"}
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "Email já registrado"

def test_get_users(client):
    # Cria alguns usuários
    users_data = [
        {"name": "User 1", "email": "user1@example.com", "password": "pass1"},
        {"name": "User 2", "email": "user2@example.com", "password": "pass2"},
    ]
    for user_data in users_data:
        client.post("/users/", json=user_data)
    
    response = client.get("/users/")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["name"] == "User 1"
    assert data[1]["name"] == "User 2"

def test_get_user(client):
    # Cria um usuário
    response = client.post(
        "/users/",
        json={"name": "Test User", "email": "test@example.com", "password": "password123"}
    )
    user_id = response.json()["id"]
    
    # Busca o usuário
    response = client.get(f"/users/{user_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Test User"
    assert data["email"] == "test@example.com"

def test_update_user(client):
    # Cria um usuário
    response = client.post(
        "/users/",
        json={"name": "Test User", "email": "test@example.com", "password": "password123"}
    )
    user_id = response.json()["id"]
    
    # Atualiza o usuário
    response = client.put(
        f"/users/{user_id}",
        json={"name": "Updated User"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Updated User"
    assert data["email"] == "test@example.com"

def test_delete_user(client):
    # Cria um usuário
    response = client.post(
        "/users/",
        json={"name": "Test User", "email": "test@example.com", "password": "password123"}
    )
    user_id = response.json()["id"]
    
    # Remove o usuário
    response = client.delete(f"/users/{user_id}")
    assert response.status_code == 204
    
    # Verifica se o usuário foi removido
    response = client.get(f"/users/{user_id}")
    assert response.status_code == 404 