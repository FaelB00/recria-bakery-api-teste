from pydantic import BaseModel


class PaginationMetaDTO(BaseModel):
    page: int
    page_size: int
    total: int