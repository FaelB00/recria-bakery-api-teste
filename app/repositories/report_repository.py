from datetime import datetime

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

_INGREDIENT_REPORT_QUERY = text("""
    SELECT
        i.id AS ingredient_id,
        i.name AS ingredient_name,
        i.measure_unit AS measure_unit,
        COALESCE(SUM(sm.quantity) FILTER (WHERE sm.movement_type = 'ORDER_RECEIPT'), 0) AS total_received,
        COALESCE(-SUM(sm.quantity) FILTER (WHERE sm.movement_type = 'CONSUMPTION'), 0) AS total_consumed,
        COALESCE(-SUM(sm.quantity) FILTER (WHERE sm.movement_type = 'WASTE'), 0) AS total_wasted,
        (
            SELECT sm2.unit_cost
            FROM bakery.stock_movements sm2
            WHERE sm2.ingredient_id = i.id
              AND sm2.store_code = i.store_code
              AND sm2.moved_at BETWEEN :from_date AND :to_date
            ORDER BY sm2.moved_at DESC
            LIMIT 1
        ) AS last_unit_cost,
        i.computed_stock AS current_stock
    FROM bakery.ingredients i
    LEFT JOIN bakery.stock_movements sm
        ON sm.ingredient_id = i.id
        AND sm.store_code = i.store_code
        AND sm.moved_at BETWEEN :from_date AND :to_date
    WHERE i.store_code = :store_code
    GROUP BY i.id, i.store_code, i.name, i.measure_unit, i.computed_stock
    ORDER BY i.name
    LIMIT :limit OFFSET :offset
""")

_INGREDIENT_REPORT_COUNT_QUERY = text("""
    SELECT COUNT(*) FROM bakery.ingredients WHERE store_code = :store_code
""")


class ReportRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_ingredient_report(
        self,
        store_code: str,
        from_date: datetime,
        to_date: datetime,
        page: int,
        page_size: int,
    ) -> tuple[list[dict], int]:
        result = await self.session.execute(
            _INGREDIENT_REPORT_QUERY,
            {
                "store_code": store_code,
                "from_date": from_date,
                "to_date": to_date,
                "limit": page_size,
                "offset": (page - 1) * page_size,
            },
        )
        rows = [dict(row._mapping) for row in result]

        total = await self.session.scalar(
            _INGREDIENT_REPORT_COUNT_QUERY, {"store_code": store_code}
        )

        return rows, total or 0