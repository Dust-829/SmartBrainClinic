"""Shared authentication helpers for administrative APIs."""

import secrets
from datetime import datetime, timedelta, timezone
from typing import Annotated, Optional

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel

from app.common.config import BaseMicroserviceSettings


_bearer_scheme = HTTPBearer(auto_error=False)


class AdminPrincipal(BaseModel):
    uuid: str
    staff_code: str
    display_name: str
    role: str = "admin"


def _jwt_settings() -> BaseMicroserviceSettings:
    settings = BaseMicroserviceSettings()
    if not settings.JWT_SECRET_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="管理员认证尚未配置",
        )
    return settings


def create_admin_access_token(*, admin_uuid: str, staff_code: str, display_name: str) -> tuple[str, int]:
    settings = _jwt_settings()
    expires_in_minutes = max(5, min(int(settings.JWT_EXPIRE_MINUTES or 60), 24 * 60))
    now = datetime.now(timezone.utc)
    payload = {
        "sub": admin_uuid,
        "role": "admin",
        "staff_code": staff_code,
        "display_name": display_name,
        "iat": now,
        "exp": now + timedelta(minutes=expires_in_minutes),
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM), expires_in_minutes * 60


async def require_admin(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer_scheme)],
) -> AdminPrincipal:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="缺少管理员登录凭据")

    settings = _jwt_settings()
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="管理员登录凭据无效或已过期")

    if payload.get("role") != "admin" or not all(
        isinstance(payload.get(key), str) and payload[key].strip()
        for key in ("sub", "staff_code", "display_name")
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无管理员访问权限")

    return AdminPrincipal(
        uuid=payload["sub"],
        staff_code=payload["staff_code"],
        display_name=payload["display_name"],
    )


async def require_ai_audit_admin(
    x_ai_audit_token: Annotated[Optional[str], Header(alias="X-AI-Audit-Token")] = None,
    x_admin_token: Annotated[Optional[str], Header(alias="X-Admin-Token")] = None,
) -> None:
    settings = BaseMicroserviceSettings()
    expected = settings.AI_AUDIT_ADMIN_TOKEN or settings.ADMIN_API_TOKEN
    provided = x_ai_audit_token or x_admin_token

    if not expected:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="AI audit admin token is not configured",
        )

    if not provided or not secrets.compare_digest(provided, expected):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权访问AI审计日志",
        )
