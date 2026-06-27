"""
Idempotency helpers for high-risk write operations.

Call ``begin_idempotency`` at the start of a service operation. If it returns a
replay response, return that response immediately. Otherwise perform the
business mutation and call ``complete_idempotency`` before committing.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


@dataclass(frozen=True)
class IdempotencyContext:
    scope: str
    key: str
    request_hash: str
    is_replay: bool = False
    response: Optional[dict[str, Any]] = None


async def begin_idempotency(
    session: AsyncSession,
    *,
    scope: str,
    idempotency_key: Optional[str],
    request_payload: Any,
    processing_timeout_seconds: int = 300,
) -> IdempotencyContext:
    if not idempotency_key:
        raise ValueError("缺少 Idempotency-Key，请为高风险写操作提供幂等键")

    key = idempotency_key.strip()
    if not key:
        raise ValueError("缺少 Idempotency-Key，请为高风险写操作提供幂等键")

    request_hash = _request_hash(request_payload)

    inserted = await session.execute(
        text(
            """
            INSERT INTO idempotency_record (
                scope, idempotency_key, request_hash, status
            )
            VALUES (:scope, :idempotency_key, :request_hash, 'processing')
            ON CONFLICT (scope, idempotency_key) DO NOTHING
            RETURNING id
            """
        ),
        {
            "scope": scope,
            "idempotency_key": key,
            "request_hash": request_hash,
        },
    )
    if inserted.first():
        return IdempotencyContext(scope=scope, key=key, request_hash=request_hash)

    existing = (
        await session.execute(
            text(
                """
                SELECT request_hash, status, response_body
                     , updated_at
                FROM idempotency_record
                WHERE scope = :scope AND idempotency_key = :idempotency_key
                FOR UPDATE
                """
            ),
            {"scope": scope, "idempotency_key": key},
        )
    ).mappings().first()

    if not existing:
        raise ValueError("幂等记录异常，请重试")

    if existing["request_hash"] != request_hash:
        raise ValueError("幂等键已被不同请求使用，请更换 idempotency_key")

    if existing["status"] == "completed":
        return IdempotencyContext(
            scope=scope,
            key=key,
            request_hash=request_hash,
            is_replay=True,
            response=_json_load(existing["response_body"]),
        )

    if existing["status"] == "processing":
        if not _is_processing_stale(existing["updated_at"], processing_timeout_seconds):
            raise ValueError("相同幂等请求正在处理中，请稍后重试")

    await session.execute(
        text(
            """
            UPDATE idempotency_record
            SET status = 'processing', response_body = NULL, updated_at = CURRENT_TIMESTAMP
            WHERE scope = :scope AND idempotency_key = :idempotency_key
            """
        ),
        {"scope": scope, "idempotency_key": key},
    )
    return IdempotencyContext(scope=scope, key=key, request_hash=request_hash)


def _is_processing_stale(updated_at: Any, timeout_seconds: int) -> bool:
    if timeout_seconds <= 0 or updated_at is None:
        return False

    if isinstance(updated_at, str):
        try:
            updated_at = datetime.fromisoformat(updated_at)
        except ValueError:
            return False

    if not isinstance(updated_at, datetime):
        return False

    now = datetime.now(tz=updated_at.tzinfo) if updated_at.tzinfo else datetime.now()
    return now - updated_at > timedelta(seconds=timeout_seconds)


async def complete_idempotency(
    session: AsyncSession,
    context: Optional[IdempotencyContext],
    response: dict[str, Any],
) -> None:
    if context is None or context.is_replay:
        return

    await session.execute(
        text(
            """
            UPDATE idempotency_record
            SET status = 'completed',
                response_body = :response_body,
                updated_at = CURRENT_TIMESTAMP
            WHERE scope = :scope
              AND idempotency_key = :idempotency_key
              AND request_hash = :request_hash
            """
        ),
        {
            "scope": context.scope,
            "idempotency_key": context.key,
            "request_hash": context.request_hash,
            "response_body": _json_dump(response),
        },
    )


async def fail_idempotency(
    session: AsyncSession,
    context: Optional[IdempotencyContext],
) -> None:
    if context is None or context.is_replay:
        return

    await session.execute(
        text(
            """
            UPDATE idempotency_record
            SET status = 'failed',
                response_body = NULL,
                updated_at = CURRENT_TIMESTAMP
            WHERE scope = :scope
              AND idempotency_key = :idempotency_key
              AND request_hash = :request_hash
            """
        ),
        {
            "scope": context.scope,
            "idempotency_key": context.key,
            "request_hash": context.request_hash,
        },
    )


async def has_active_processing_request(
    session: AsyncSession,
    *,
    scope: str,
    request_payload: Any,
    exclude_idempotency_key: str,
    processing_timeout_seconds: int = 300,
) -> bool:
    request_hash = _request_hash(request_payload)
    rows = (
        await session.execute(
            text(
                """
                SELECT updated_at
                FROM idempotency_record
                WHERE scope = :scope
                  AND request_hash = :request_hash
                  AND status = 'processing'
                  AND idempotency_key <> :exclude_idempotency_key
                FOR UPDATE
                """
            ),
            {
                "scope": scope,
                "request_hash": request_hash,
                "exclude_idempotency_key": exclude_idempotency_key,
            },
        )
    ).mappings().all()
    return any(
        not _is_processing_stale(row["updated_at"], processing_timeout_seconds)
        for row in rows
    )


def _request_hash(payload: Any) -> str:
    body = _json_dump(payload)
    return hashlib.sha256(body.encode("utf-8")).hexdigest()


def _json_dump(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, default=str)


def _json_load(value: Optional[str]) -> dict[str, Any]:
    if not value:
        return {}
    data = json.loads(value)
    return data if isinstance(data, dict) else {"value": data}
