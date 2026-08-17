from datetime import datetime

from fastapi import APIRouter, Depends, Query

from app.dtos.common import PaginationMetaDTO
from app.dtos.report import IngredientReportResponseDTO
from app.infra.dependencies import get_report_service, get_store_code
from app.infra.response import error_response, ok
from app.services.errors import BusinessError
from app.services.report_service import ReportService

router = APIRouter(prefix="/v1/reports", tags=["reports"])


@router.get("/ingredients")
async def get_ingredient_report(
    from_: datetime = Query(alias="from"),
    to: datetime = Query(),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    store_code: str = Depends(get_store_code),
    service: ReportService = Depends(get_report_service),
):
    result = await service.get_ingredient_report(store_code, from_, to, page, page_size)
    if isinstance(result, BusinessError):
        return error_response(result)

    items, total = result
    response = IngredientReportResponseDTO(
        items=items,
        meta=PaginationMetaDTO(page=page, page_size=page_size, total=total),
    )
    return ok(response)