import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.dtos.common import PaginationMetaDTO

MeasureUnit = Literal["KG", "UN", "L"]


class IngredientCreateDTO(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1)
    measure_unit: MeasureUnit
    units_per_package: Decimal = Field(gt=0)
    default_supplier_id: uuid.UUID | None = None


class IngredientResponseDTO(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    measure_unit: str
    units_per_package: Decimal
    default_supplier_id: uuid.UUID | None
    computed_stock: Decimal
    average_cost: Decimal
    is_active: bool
    created_at: datetime
    updated_at: datetime


class IngredientListResponseDTO(BaseModel):
    items: list[IngredientResponseDTO]
    meta: PaginationMetaDTO