"""
通用 API 响应体封装
"""

from typing import Any, Optional
from pydantic import BaseModel


class ApiResponse(BaseModel):
    code: int = 200
    message: str = "success"
    data: Optional[Any] = None


class PageResponse(BaseModel):
    code: int = 200
    message: str = "success"
    data: Optional[Any] = None
    total: int = 0
    page: int = 1
    page_size: int = 20


def success(data: Any = None, message: str = "success") -> dict:
    return {"code": 200, "message": message, "data": data}


def created(data: Any = None, message: str = "创建成功") -> dict:
    return {"code": 201, "message": message, "data": data}


def error(code: int = 400, message: str = "请求参数错误") -> dict:
    return {"code": code, "message": message, "data": None}


def page_success(data: Any, total: int, page: int, page_size: int) -> dict:
    return {
        "code": 200,
        "message": "success",
        "data": data,
        "total": total,
        "page": page,
        "page_size": page_size,
    }
