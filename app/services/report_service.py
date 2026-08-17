from datetime import datetime

from app.dtos.report import IngredientReportRowDTO
from app.repositories.report_repository import ReportRepository
from app.services.errors import BusinessError, ErrorCode


class ReportService:
    def __init__(self, repository: ReportRepository):
        self.repository = repository

    async def get_ingredient_report(
        self,
        store_code: str,
        from_date: datetime,
        to_date: datetime,
        page: int,
        page_size: int,
    ) -> tuple[list[IngredientReportRowDTO], int] | BusinessError:
        if from_date > to_date:
            return BusinessError(
                ErrorCode.UNPROCESSABLE,
                "O parâmetro 'from' não pode ser posterior ao parâmetro 'to'",
            )

        rows, total = await self.repository.get_ingredient_report(
            store_code, from_date, to_date, page, page_size
        )

        items = [IngredientReportRowDTO(**row) for row in rows]
        return items, total