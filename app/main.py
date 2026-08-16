import logging
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from app.controllers import health

logger = logging.getLogger(__name__)

app = FastAPI(title="Bakery API")

app.include_router(health.router)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        status_code=422,
        content={"data": None, "message": "Requisição inválida"},
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Erro não tratado ao processar %s %s", request.method, request.url)
    return JSONResponse(
        status_code=500,
        content={"data": None, "message": "Erro interno do servidor"},
    )