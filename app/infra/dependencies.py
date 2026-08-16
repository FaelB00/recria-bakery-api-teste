import re
from fastapi import Header

STORE_CODE_PATTERN = re.compile(r"^\d{8}$")


async def get_store_code(x_store_code: str = Header(..., pattern=STORE_CODE_PATTERN.pattern)) -> str:
    return x_store_code
