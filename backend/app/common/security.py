"""
Lightweight security dependencies shared by internal admin endpoints.
"""

import secrets
from typing import Annotated, Optional

from fastapi import Header, HTTPException, status

from app.common.config import BaseMicroserviceSettings


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
