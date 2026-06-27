"""
Best-effort AI audit logging.

The audit writer records AI module, source, model, desensitized input/output
summaries, warnings, validator messages, and latency. Failures are logged but
never raised, so audit persistence cannot break business workflows.
"""

import json
import logging
import re
import time
import uuid
from datetime import datetime
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.config import BaseMicroserviceSettings

logger = logging.getLogger("common.ai_audit")

_engine: Optional[AsyncEngine] = None

SENSITIVE_KEYS = {
    "api_key",
    "apikey",
    "authorization",
    "birthdate",
    "card_number",
    "home_address",
    "id_card",
    "identity_card",
    "mobile",
    "name",
    "password",
    "patient_name",
    "phone",
    "real_name",
    "realname",
    "token",
}

PHONE_PATTERN = re.compile(r"(?<!\d)1[3-9]\d{9}(?!\d)")
ID_CARD_PATTERN = re.compile(
    r"(?<!\d)\d{6}(?:19|20)\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])\d{3}[\dXx](?!\d)"
)
LONG_NUMBER_PATTERN = re.compile(r"(?<!\d)\d{12,}(?!\d)")
EMAIL_PATTERN = re.compile(r"([A-Za-z0-9._%+-]{2})[A-Za-z0-9._%+-]*(@[A-Za-z0-9.-]+\.[A-Za-z]{2,})")
SECRET_PATTERN = re.compile(r"(?i)(sk-|api[_-]?key[=:]\s*)[A-Za-z0-9_\-]{8,}")


def start_ai_timer() -> float:
    return time.perf_counter()


def elapsed_ms(started_at: Optional[float]) -> Optional[int]:
    if started_at is None:
        return None
    return int((time.perf_counter() - started_at) * 1000)


async def record_ai_audit(
    *,
    module_name: str,
    input_text: Any,
    result: dict,
    context: Optional[dict[str, Any]] = None,
    latency_ms: Optional[int] = None,
) -> None:
    try:
        engine = _get_engine()

        async with engine.begin() as conn:
            await conn.execute(
                text(
                    """
                    INSERT INTO ai_audit_log (
                        uuid,
                        module_name,
                        source,
                        model,
                        input_summary,
                        output_summary,
                        warnings,
                        validated,
                        validator_messages,
                        latency_ms,
                        context
                    ) VALUES (
                        :uuid,
                        :module_name,
                        :source,
                        :model,
                        :input_summary,
                        :output_summary,
                        :warnings,
                        :validated,
                        :validator_messages,
                        :latency_ms,
                        :context
                    )
                    """
                ),
                {
                    "uuid": str(uuid.uuid4()),
                    "module_name": module_name,
                    "source": result.get("source"),
                    "model": result.get("model"),
                    "input_summary": _summarize(input_text),
                    "output_summary": _summarize(result.get("data")),
                    "warnings": _json_dump(result.get("warnings", [])),
                    "validated": bool(result.get("validated", False)),
                    "validator_messages": _json_dump(result.get("validator_messages", [])),
                    "latency_ms": latency_ms,
                    "context": _json_dump(context or {}),
                },
            )
    except Exception as exc:
        logger.warning("[AI Audit] Failed to write audit log: %s", exc)


async def query_ai_audit_logs(
    session: AsyncSession,
    *,
    module_name: Optional[str] = None,
    source: Optional[str] = None,
    validated: Optional[bool] = None,
    created_from: Optional[datetime] = None,
    created_to: Optional[datetime] = None,
    limit: int = 50,
    offset: int = 0,
) -> list[dict[str, Any]]:
    limit = max(1, min(limit, 200))
    offset = max(0, offset)
    where_sql = ["1 = 1"]
    params: dict[str, Any] = {"limit": limit, "offset": offset}

    if module_name:
        where_sql.append("module_name = :module_name")
        params["module_name"] = module_name
    if source:
        where_sql.append("source = :source")
        params["source"] = source
    if validated is not None:
        where_sql.append("validated = :validated")
        params["validated"] = validated
    if created_from:
        where_sql.append("created_at >= :created_from")
        params["created_from"] = created_from
    if created_to:
        where_sql.append("created_at <= :created_to")
        params["created_to"] = created_to

    result = await session.execute(
        text(
            f"""
            SELECT
                uuid,
                module_name,
                source,
                model,
                input_summary,
                output_summary,
                warnings,
                validated,
                validator_messages,
                latency_ms,
                context,
                created_at
            FROM ai_audit_log
            WHERE {' AND '.join(where_sql)}
            ORDER BY created_at DESC
            LIMIT :limit OFFSET :offset
            """
        ),
        params,
    )
    return [_serialize_audit_row(row) for row in result.mappings().all()]


def _get_engine() -> AsyncEngine:
    global _engine
    if _engine is None:
        settings = BaseMicroserviceSettings()
        _engine = create_async_engine(settings.get_db_url(), echo=False)
    return _engine


def _summarize(value: Any, max_len: int = 1000) -> str:
    value = redact_sensitive_data(value)
    if isinstance(value, str):
        text_value = value
    else:
        text_value = _json_dump(value)
    return text_value[:max_len]


def redact_sensitive_data(value: Any) -> Any:
    if isinstance(value, dict):
        redacted: dict[Any, Any] = {}
        for key, item in value.items():
            key_text = str(key).lower()
            has_sensitive_token = any(
                token in key_text for token in ("password", "token", "api_key")
            )
            if key_text in SENSITIVE_KEYS or has_sensitive_token:
                redacted[key] = "[REDACTED]"
            else:
                redacted[key] = redact_sensitive_data(item)
        return redacted
    if isinstance(value, list):
        return [redact_sensitive_data(item) for item in value]
    if isinstance(value, tuple):
        return tuple(redact_sensitive_data(item) for item in value)
    if isinstance(value, str):
        return _redact_text(value)
    return value


def _redact_text(value: str) -> str:
    value = PHONE_PATTERN.sub(lambda match: f"{match.group(0)[:3]}****{match.group(0)[-4:]}", value)
    value = ID_CARD_PATTERN.sub(lambda match: f"{match.group(0)[:6]}********{match.group(0)[-4:]}", value)
    value = LONG_NUMBER_PATTERN.sub(lambda match: f"{match.group(0)[:4]}****{match.group(0)[-4:]}", value)
    value = EMAIL_PATTERN.sub(lambda match: f"{match.group(1)}***{match.group(2)}", value)
    value = SECRET_PATTERN.sub(lambda match: f"{match.group(1)}[REDACTED]", value)
    return value


def _serialize_audit_row(row: dict[str, Any]) -> dict[str, Any]:
    created_at = row.get("created_at")
    return {
        "uuid": str(row.get("uuid")),
        "module_name": row.get("module_name"),
        "source": row.get("source"),
        "model": row.get("model"),
        "input_summary": row.get("input_summary"),
        "output_summary": row.get("output_summary"),
        "warnings": _json_load(row.get("warnings")),
        "validated": bool(row.get("validated")),
        "validator_messages": _json_load(row.get("validator_messages")),
        "latency_ms": row.get("latency_ms"),
        "context": _json_load(row.get("context")),
        "created_at": created_at.isoformat() if created_at else None,
    }


def _json_dump(value: Any) -> str:
    try:
        return json.dumps(value, ensure_ascii=False, default=str)
    except TypeError:
        return str(value)


def _json_load(value: Any) -> Any:
    if value in (None, ""):
        return []
    if not isinstance(value, str):
        return value
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return value
