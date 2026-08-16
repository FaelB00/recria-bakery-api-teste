from fastapi import status
from fastapi.responses import JSONResponse
from app.services.errors import BusinessError, ErrorCode

_STATUS_BY_CODE = {
    ErrorCode.NOT_FOUND: status.HTTP_404_NOT_FOUND,
    ErrorCode.CONFLICT: status.HTTP_409_CONFLICT,
    ErrorCode.UNPROCESSABLE: status.HTTP_422_UNPROCESSABLE_ENTITY,
}


def ok(data) -> dict:
    return {"data": data, "message": "OK"}


def created(data) -> dict:
    return {"data": data, "message": "Created"}


def error_response(err: BusinessError) -> JSONResponse:
    http_status = _STATUS_BY_CODE[err.code]
    return JSONResponse(
        status_code=http_status,
        content={"data": None, "message": err.message},
    )