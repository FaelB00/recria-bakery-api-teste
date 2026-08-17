import re

from fastapi import Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db_session
from app.repositories.supplier_repository import SupplierRepository
from app.services.supplier_service import SupplierService
from app.repositories.ingredient_repository import IngredientRepository
from app.services.ingredient_service import IngredientService

STORE_CODE_PATTERN = re.compile(r"^\d{8}$")


async def get_store_code(x_store_code: str = Header(..., pattern=STORE_CODE_PATTERN.pattern)) -> str:
    return x_store_code


def get_supplier_repository(session: AsyncSession = Depends(get_db_session)) -> SupplierRepository:
    return SupplierRepository(session)


def get_supplier_service(
    repository: SupplierRepository = Depends(get_supplier_repository),
) -> SupplierService:
    return SupplierService(repository)


def get_ingredient_repository(session: AsyncSession = Depends(get_db_session)) -> IngredientRepository:
    return IngredientRepository(session)


def get_ingredient_service(
    repository: IngredientRepository = Depends(get_ingredient_repository),
) -> IngredientService:
    return IngredientService(repository)