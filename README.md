# API de Usuários com FastAPI

API RESTful moderna usando FastAPI, SQLAlchemy e Pydantic.

## Características

- FastAPI para alta performance e tipagem automática
- SQLAlchemy para ORM
- Pydantic para validação de dados
- Testes automatizados com pytest
- Documentação automática (Swagger/OpenAPI)

## Instalação

1. Clone o repositório
2. Crie um ambiente virtual:
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
```

3. Instale as dependências:
```bash
pip install -r requirements.txt
```

## Executando

1. Inicie o servidor:
```bash
uvicorn main:app --reload
```

2. Acesse a documentação:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Endpoints

- `GET /users/`: Lista usuários
- `POST /users/`: Cria usuário
- `GET /users/{id}`: Obtém usuário
- `PUT /users/{id}`: Atualiza usuário
- `DELETE /users/{id}`: Remove usuário

## Testes

Execute os testes com:
```bash
pytest
```

## Estrutura do Projeto

```
.
├── models.py           # Modelos SQLAlchemy
├── users_router.py     # Rotas da API
├── test_users.py       # Testes
└── requirements.txt    # Dependências
``` 