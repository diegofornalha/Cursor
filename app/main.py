from fastapi import FastAPI
from app.api.users import router as users_router

app = FastAPI(title="Cline API")

app.include_router(users_router)
