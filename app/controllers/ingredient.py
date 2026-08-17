import uuid

from fastapi import APIRouter, Depends, Query

from app.dtos.common import PaginationMetaDTO
from app.dtos.ingredient import IngredientCreateDTO, IngredientListResponseDTO, IngredientResponseDTO
from app.infra.dependencies import get_ingredient_service, get_store_code
from app.infra.response import created, error_response, ok
from app.services.errors import BusinessError
from app.services.ingredient_service import IngredientService

router = APIRouter(prefix="/v1/ingredients", tags=["ingredients"])


@router.get("")
async def list_ingredients(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
    supplier_id: uuid.UUID | None = Query(default=None),
    store_code: str = Depends(get_store_code),
    service: IngredientService = Depends(get_ingredient_service),
):
    items, total = await service.list_ingredients(store_code, page, page_size, search, supplier_id)
    response = IngredientListResponseDTO(
        items=[IngredientResponseDTO.model_validate(item) for item in items],
        meta=PaginationMetaDTO(page=page, page_size=page_size, total=total),
    )
    return ok(response)


@router.get("/{ingredient_id}")
async def get_ingredient(
    ingredient_id: uuid.UUID,
    store_code: str = Depends(get_store_code),
    service: IngredientService = Depends(get_ingredient_service),
):
    result = await service.get_ingredient(ingredient_id, store_code)
    if isinstance(result, BusinessError):
        return error_response(result)
    return ok(IngredientResponseDTO.model_validate(result))


@router.post("", status_code=201)
async def create_ingredient(
    body: IngredientCreateDTO,
    store_code: str = Depends(get_store_code),
    service: IngredientService = Depends(get_ingredient_service),
):
    result = await service.create_ingredient(store_code, body)
    if isinstance(result, BusinessError):
        return error_response(result)
    return created(IngredientResponseDTO.model_validate(result))