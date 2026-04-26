import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import ORJSONResponse

from .config import get_settings
from .routers import accounts, ai, auth, categories, households, notifications, recurring, reports, transactions

_settings = get_settings()

logging.basicConfig(level=getattr(logging, _settings.log_level, logging.INFO))

app = FastAPI(
    title="Evimiz API",
    description="Aile gelir-gider yönetimi · AI destekli",
    version="0.1.0",
    default_response_class=ORJSONResponse,
)

origins = ["*"] if _settings.allowed_origins.strip() == "*" else [
    o.strip() for o in _settings.allowed_origins.split(",") if o.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok", "env": _settings.environment}


app.include_router(auth.router, prefix="/api")
app.include_router(households.router, prefix="/api")
app.include_router(categories.router, prefix="/api")
app.include_router(accounts.router, prefix="/api")
app.include_router(transactions.router, prefix="/api")
app.include_router(ai.router, prefix="/api")
app.include_router(reports.router, prefix="/api")
app.include_router(recurring.router, prefix="/api")
app.include_router(notifications.router, prefix="/api")
