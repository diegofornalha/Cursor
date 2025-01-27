# Cline API

API simples com endpoint de health check para monitoramento.

## Instalação

1. Clone o repositório
2. Crie um ambiente virtual:
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
.\venv\Scripts\activate  # Windows
```
3. Instale as dependências:
```bash
pip install -r requirements.txt
```

## Executando

Para iniciar o servidor:

```bash
uvicorn app.main:app --reload
```

O servidor estará disponível em `http://localhost:8000`

## Endpoints

### Health Check

- **URL**: `/health`
- **Método**: GET
- **Resposta de Sucesso**:
  ```json
  {
    "status": "ok",
    "timestamp": "2024-03-21T10:00:00.000000",
    "service": "Cline API"
  }
  ```
