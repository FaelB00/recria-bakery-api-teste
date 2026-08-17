import re
import uuid

from app.dtos.supplier import SupplierCreateDTO, SupplierUpdateDTO
from app.models.supplier import Supplier
from app.repositories.supplier_repository import SupplierRepository
from app.services.errors import BusinessError, ErrorCode

_DIGITS_ONLY = re.compile(r"\D")


def _normalize_phone(raw_phone: str) -> str:
    return _DIGITS_ONLY.sub("", raw_phone)


class SupplierService:
    def __init__(self, repository: SupplierRepository):
        self.repository = repository

    async def get_supplier(self, supplier_id: uuid.UUID, store_code: str) -> Supplier | BusinessError:
        supplier = await self.repository.get_by_id(supplier_id, store_code)
        if supplier is None:
            return BusinessError(ErrorCode.NOT_FOUND, f"Fornecedor '{supplier_id}' não encontrado")
        return supplier

    async def list_suppliers(
        self,
        store_code: str,
        page: int,
        page_size: int,
        search: str | None,
        is_active: bool,
    ) -> tuple[list[Supplier], int]:
        return await self.repository.list(store_code, page, page_size, search, is_active)

    async def create_supplier(self, store_code: str, data: SupplierCreateDTO) -> Supplier | BusinessError:
        phone = _normalize_phone(data.contact_phone)

        existing = await self.repository.get_by_phone(phone, store_code)
        if existing is not None:
            return BusinessError(ErrorCode.CONFLICT, f"Telefone '{phone}' já cadastrado nesta loja")

        supplier = Supplier(
            store_code=store_code,
            name=data.name,
            contact_phone=phone,
        )
        return await self.repository.create(supplier)

    async def update_supplier(
        self, supplier_id: uuid.UUID, store_code: str, data: SupplierUpdateDTO
    ) -> Supplier | BusinessError:
        supplier = await self.repository.get_by_id(supplier_id, store_code)
        if supplier is None:
            return BusinessError(ErrorCode.NOT_FOUND, f"Fornecedor '{supplier_id}' não encontrado")

        changes = data.model_dump(exclude_unset=True)

        if "contact_phone" in changes:
            phone = _normalize_phone(changes["contact_phone"])
            existing = await self.repository.get_by_phone(phone, store_code)
            if existing is not None and existing.id != supplier.id:
                return BusinessError(ErrorCode.CONFLICT, f"Telefone '{phone}' já cadastrado nesta loja")
            changes["contact_phone"] = phone

        return await self.repository.update(supplier, changes)

    async def deactivate_supplier(self, supplier_id: uuid.UUID, store_code: str) -> None | BusinessError:
        supplier = await self.repository.get_by_id(supplier_id, store_code)
        if supplier is None:
            return BusinessError(ErrorCode.NOT_FOUND, f"Fornecedor '{supplier_id}' não encontrado")

        await self.repository.deactivate(supplier)
        return None