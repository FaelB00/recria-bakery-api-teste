from dataclasses import dataclass
from enum import StrEnum


class ErrorCode(StrEnum):
    NOT_FOUND = "NOT_FOUND"
    CONFLICT = "CONFLICT"
    UNPROCESSABLE = "UNPROCESSABLE"


@dataclass(frozen=True)
class BusinessError:
    code: ErrorCode
    message: str

