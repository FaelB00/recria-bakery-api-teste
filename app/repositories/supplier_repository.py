import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.supplier import Supplier


class SupplierRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, supplier_id: uuid.UUID, store_code: str) -> Supplier | None:
        stmt = select(Supplier).where(
            Supplier.id == supplier_id,
            Supplier.store_code == store_code,
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_phone(self, contact_phone: str, store_code: str) -> Supplier | None:
        stmt = select(Supplier).where(
            Supplier.contact_phone == contact_phone,
            Supplier.store_code == store_code,
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def list(
        self,
        store_code: str,
        page: int,
        page_size: int,
        search: str | None,
        is_active: bool,
    ) -> tuple[list[Supplier], int]:
        conditions = [
            Supplier.store_code == store_code,
            Supplier.is_active == is_active,
        ]
        if search:
            conditions.append(Supplier.name.ilike(f"%{search}%"))

        count_stmt = select(func.count()).select_from(Supplier).where(*conditions)
        total = await self.session.scalar(count_stmt)

        stmt = (
            select(Supplier)
            .where(*conditions)
            .order_by(Supplier.name)
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        result = await self.session.execute(stmt)
        items = list(result.scalars().all())

        return items, total or 0

    async def create(self, supplier: Supplier) -> Supplier:
        self.session.add(supplier)
        await self.session.flush()
        await self.session.refresh(supplier)
        return supplier

    async def update(self, supplier: Supplier, changes: dict) -> Supplier:
        for field, value in changes.items():
            setattr(supplier, field, value)
        await self.session.flush()
        await self.session.refresh(supplier)
        return supplier

    async def deactivate(self, supplier: Supplier) -> None:
        supplier.is_active = False
        await self.session.flush()