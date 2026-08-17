import re

from fastapi import Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db_session
from app.repositories.ingredient_repository import IngredientRepository
from app.repositories.report_repository import ReportRepository
from app.repositories.supplier_repository import SupplierRepository
from app.services.ingredient_service import IngredientService
from app.services.report_service import ReportService
from app.services.supplier_service import SupplierService

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


def get_report_repository(session: AsyncSession = Depends(get_db_session)) -> ReportRepository:
    return ReportRepository(session)


def get_report_service(
    repository: ReportRepository = Depends(get_report_repository),
) -> ReportService:
    return ReportService(repository)