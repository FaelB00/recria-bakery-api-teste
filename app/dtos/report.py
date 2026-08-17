import uuid
from decimal import Decimal

from pydantic import BaseModel

from app.dtos.common import PaginationMetaDTO


class IngredientReportRowDTO(BaseModel):
    ingredient_id: uuid.UUID
    ingredient_name: str
    measure_unit: str
    total_received: Decimal
    total_consumed: Decimal
    total_wasted: Decimal
    last_unit_cost: Decimal | None
    current_stock: Decimal


class IngredientReportResponseDTO(BaseModel):
    items: list[IngredientReportRowDTO]
    meta: PaginationMetaDTO