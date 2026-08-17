import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    ForeignKeyConstraint,
    Numeric,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class Ingredient(Base):
    __tablename__ = "ingredients"
    __table_args__ = (
        UniqueConstraint("store_code", "name", name="uq_ingredients_name"),
        CheckConstraint("store_code ~ '^[0-9]{8}$'", name="ck_ingredients_store_code"),
        CheckConstraint("units_per_package > 0", name="ck_ingredients_upp"),
        CheckConstraint("measure_unit IN ('KG', 'UN', 'L')", name="ck_ingredients_unit"),
        ForeignKeyConstraint(
            ["default_supplier_id", "store_code"],
            ["bakery.suppliers.id", "bakery.suppliers.store_code"],
            name="fk_ingredients_supplier",
        ),
        {"schema": "bakery"},
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    store_code: Mapped[str] = mapped_column(String(8), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    measure_unit: Mapped[str] = mapped_column(String(10), nullable=False)
    units_per_package: Mapped[Decimal] = mapped_column(Numeric(12, 3), nullable=False)
    default_supplier_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    computed_stock: Mapped[Decimal] = mapped_column(Numeric(14, 3), nullable=False, default=0)
    average_cost: Mapped[Decimal] = mapped_column(Numeric(14, 4), nullable=False, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(server_default=func.now())