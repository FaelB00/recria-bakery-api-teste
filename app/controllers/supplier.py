import uuid
from typing import Any
from fastapi.responses import JSONResponse
from fastapi import APIRouter, Depends, Query

from app.dtos.supplier import (
    PaginationMetaDTO,
    SupplierCreateDTO,
    SupplierListResponseDTO,
    SupplierResponseDTO,
    SupplierUpdateDTO,
)
from app.infra.dependencies import get_store_code, get_supplier_service
from app.infra.response import created, error_response, ok
from app.services.errors import BusinessError
from app.services.supplier_service import SupplierService

router = APIRouter(prefix="/v1/suppliers", tags=["suppliers"])


@router.get("")
async def list_suppliers(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
    is_active: bool = Query(default=True),
    store_code: str = Depends(get_store_code),
    service: SupplierService = Depends(get_supplier_service),
) -> dict[str, Any] | JSONResponse:
    items, total = await service.list_suppliers(store_code, page, page_size, search, is_active)
    response = SupplierListResponseDTO(
        items=[SupplierResponseDTO.model_validate(item) for item in items],
        meta=PaginationMetaDTO(page=page, page_size=page_size, total=total),
    )
    return ok(response)


@router.get("/{supplier_id}")
async def get_supplier(
    supplier_id: uuid.UUID,
    store_code: str = Depends(get_store_code),
    service: SupplierService = Depends(get_supplier_service),
) -> dict[str, Any] | JSONResponse:
    result = await service.get_supplier(supplier_id, store_code)
    if isinstance(result, BusinessError):
        return error_response(result)
    return ok(SupplierResponseDTO.model_validate(result))


@router.post("", status_code=201)
async def create_supplier(
    body: SupplierCreateDTO,
    store_code: str = Depends(get_store_code),
    service: SupplierService = Depends(get_supplier_service),
) -> dict[str, Any] | JSONResponse:
    result = await service.create_supplier(store_code, body)
    if isinstance(result, BusinessError):
        return error_response(result)
    return created(SupplierResponseDTO.model_validate(result))


@router.patch("/{supplier_id}")
async def update_supplier(
    supplier_id: uuid.UUID,
    body: SupplierUpdateDTO,
    store_code: str = Depends(get_store_code),
    service: SupplierService = Depends(get_supplier_service),
) -> dict[str, Any] | JSONResponse:
    result = await service.update_supplier(supplier_id, store_code, body)
    if isinstance(result, BusinessError):
        return error_response(result)
    return ok(SupplierResponseDTO.model_validate(result))


@router.delete("/{supplier_id}", status_code=204)
async def delete_supplier(
    supplier_id: uuid.UUID,
    store_code: str = Depends(get_store_code),
    service: SupplierService = Depends(get_supplier_service),
) -> dict[str, Any] | JSONResponse | None:
    result = await service.deactivate_supplier(supplier_id, store_code)
    if isinstance(result, BusinessError):
        return error_response(result)
    return None