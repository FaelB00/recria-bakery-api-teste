import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.ingredient import Ingredient
from app.models.supplier import Supplier


class IngredientRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, ingredient_id: uuid.UUID, store_code: str) -> Ingredient | None:
        stmt = select(Ingredient).where(
            Ingredient.id == ingredient_id,
            Ingredient.store_code == store_code,
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def supplier_exists(self, supplier_id: uuid.UUID, store_code: str) -> bool:
        stmt = select(Supplier.id).where(
            Supplier.id == supplier_id,
            Supplier.store_code == store_code,
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none() is not None

    async def list(
        self,
        store_code: str,
        page: int,
        page_size: int,
        search: str | None,
        supplier_id: uuid.UUID | None,
    ) -> tuple[list[Ingredient], int]:
        conditions = [Ingredient.store_code == store_code]
        if search:
            conditions.append(Ingredient.name.ilike(f"%{search}%"))
        if supplier_id:
            conditions.append(Ingredient.default_supplier_id == supplier_id)

        count_stmt = select(func.count()).select_from(Ingredient).where(*conditions)
        total = await self.session.scalar(count_stmt)

        stmt = (
            select(Ingredient)
            .where(*conditions)
            .order_by(Ingredient.name)
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        result = await self.session.execute(stmt)
        items = list(result.scalars().all())

        return items, total or 0

    async def create(self, ingredient: Ingredient) -> Ingredient:
        self.session.add(ingredient)
        await self.session.flush()
        await self.session.refresh(ingredient)
        return ingredient