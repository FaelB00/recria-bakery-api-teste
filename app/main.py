import logging
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from app.controllers import health

app = FastAPI(title="Bakery API")

app.include_router(health.router)
