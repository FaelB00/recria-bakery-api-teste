import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class SupplierCreateDTO(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1)
    contact_phone: str = Field(min_length=1)


class SupplierUpdateDTO(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(default=None, min_length=1)
    contact_phone: str | None = Field(default=None, min_length=1)
    is_active: bool | None = None


class SupplierResponseDTO(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    contact_phone: str
    is_active: bool
    created_at: datetime
    updated_at: datetime


class PaginationMetaDTO(BaseModel):
    page: int
    page_size: int
    total: int


class SupplierListResponseDTO(BaseModel):
    items: list[SupplierResponseDTO]
    meta: PaginationMetaDTO