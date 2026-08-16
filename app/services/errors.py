from dataclasses import dataclass
from enum import Enum

class ErrorCode(str, Enum):
    NOT_FOUND = "NOT_FOUND"
    CONFLICT = "CONFLICT"
    UNPROCESSABLE = "UNPROCESSABLE"


@dataclass(frozen=True)
class BusinessError:
    code: ErrorCode
    message: str

