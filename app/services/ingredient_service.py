import uuid

from app.dtos.ingredient import IngredientCreateDTO
from app.models.ingredient import Ingredient
from app.repositories.ingredient_repository import IngredientRepository
from app.services.errors import BusinessError, ErrorCode


class IngredientService:
    def __init__(self, repository: IngredientRepository):
        self.repository = repository

    async def get_ingredient(self, ingredient_id: uuid.UUID, store_code: str) -> Ingredient | BusinessError:
        ingredient = await self.repository.get_by_id(ingredient_id, store_code)
        if ingredient is None:
            return BusinessError(ErrorCode.NOT_FOUND, f"Insumo '{ingredient_id}' não encontrado")
        return ingredient

    async def list_ingredients(
        self,
        store_code: str,
        page: int,
        page_size: int,
        search: str | None,
        supplier_id: uuid.UUID | None,
    ) -> tuple[list[Ingredient], int]:
        return await self.repository.list(store_code, page, page_size, search, supplier_id)

    async def create_ingredient(
        self, store_code: str, data: IngredientCreateDTO
    ) -> Ingredient | BusinessError:
        if data.default_supplier_id is not None:
            exists = await self.repository.supplier_exists(data.default_supplier_id, store_code)
            if not exists:
                return BusinessError(
                    ErrorCode.NOT_FOUND,
                    f"Fornecedor '{data.default_supplier_id}' não encontrado",
                )

        ingredient = Ingredient(
            store_code=store_code,
            name=data.name,
            measure_unit=data.measure_unit,
            units_per_package=data.units_per_package,
            default_supplier_id=data.default_supplier_id,
        )
        return await self.repository.create(ingredient)