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
from csv import writer
from datetime import datetime
from io import StringIO
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.config import BaseMicroserviceSettings

logger = logging.getLogger("common.ai_audit")

_engine: Optional[AsyncEngine] = None
REVIEW_PENDING = "pending"
REVIEW_APPROVED = "approved"
REVIEW_REJECTED = "rejected"
REVIEW_STATUSES = {REVIEW_PENDING, REVIEW_APPROVED, REVIEW_REJECTED}

AUDIT_SELECT_COLUMNS = """
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
    review_status,
    review_note,
    reviewer,
    reviewed_at,
    created_at
"""

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
) -> dict[str, Any]:
    limit = max(1, min(limit, 200))
    offset = max(0, offset)
    where_sql, params = _build_audit_filters(
        module_name=module_name,
        source=source,
        validated=validated,
        created_from=created_from,
        created_to=created_to,
    )
    item_params = {**params, "limit": limit, "offset": offset}

    item_result = await session.execute(
        text(
            f"""
            SELECT
                {AUDIT_SELECT_COLUMNS}
            FROM ai_audit_log
            WHERE {' AND '.join(where_sql)}
            ORDER BY created_at DESC
            LIMIT :limit OFFSET :offset
            """
        ),
        item_params,
    )
    item_rows = item_result.mappings().all()
    items = [_serialize_audit_row(row) for row in item_rows]

    summary_result = await session.execute(
        text(
            f"""
            SELECT
                COUNT(*) AS total_count,
                COALESCE(SUM(CASE WHEN validated THEN 1 ELSE 0 END), 0) AS validated_count,
                COALESCE(SUM(CASE WHEN validated THEN 0 ELSE 1 END), 0) AS pending_count,
                COALESCE(SUM(CASE WHEN review_status = 'pending' THEN 1 ELSE 0 END), 0) AS review_pending_count,
                COALESCE(SUM(CASE WHEN review_status = 'approved' THEN 1 ELSE 0 END), 0) AS review_approved_count,
                COALESCE(SUM(CASE WHEN review_status = 'rejected' THEN 1 ELSE 0 END), 0) AS review_rejected_count
            FROM ai_audit_log
            WHERE {' AND '.join(where_sql)}
            """
        ),
        params,
    )
    summary_row = summary_result.mappings().all()
    summary = _build_audit_summary(summary_row[0] if summary_row else None, items)
    return {
        "items": items,
        "pagination": {
            "total": summary["total_count"],
            "limit": limit,
            "offset": offset,
        },
        "summary": summary,
    }


async def get_ai_audit_log(session: AsyncSession, audit_uuid: str) -> Optional[dict[str, Any]]:
    result = await session.execute(
        text(
            f"""
            SELECT
                {AUDIT_SELECT_COLUMNS}
            FROM ai_audit_log
            WHERE uuid = :audit_uuid
            LIMIT 1
            """
        ),
        {"audit_uuid": audit_uuid},
    )
    rows = result.mappings().all()
    if not rows:
        return None
    return _serialize_audit_row(rows[0])


async def review_ai_audit_log(
    session: AsyncSession,
    audit_uuid: str,
    *,
    review_status: str,
    review_note: Optional[str] = None,
    reviewer: Optional[str] = None,
) -> Optional[dict[str, Any]]:
    normalized_status = str(review_status or "").strip().lower()
    if normalized_status not in REVIEW_STATUSES - {REVIEW_PENDING}:
        raise ValueError("无效的人工复核状态")

    result = await session.execute(
        text(
            f"""
            UPDATE ai_audit_log
            SET
                review_status = :review_status,
                review_note = :review_note,
                reviewer = :reviewer,
                reviewed_at = CURRENT_TIMESTAMP
            WHERE uuid = :audit_uuid
            RETURNING
                {AUDIT_SELECT_COLUMNS}
            """
        ),
        {
            "audit_uuid": audit_uuid,
            "review_status": normalized_status,
            "review_note": review_note.strip() if isinstance(review_note, str) else review_note,
            "reviewer": reviewer.strip() if isinstance(reviewer, str) else reviewer,
        },
    )
    rows = result.mappings().all()
    if not rows:
        return None
    await session.commit()
    return _serialize_audit_row(rows[0])


async def export_ai_audit_logs_csv(
    session: AsyncSession,
    *,
    module_name: Optional[str] = None,
    source: Optional[str] = None,
    validated: Optional[bool] = None,
    created_from: Optional[datetime] = None,
    created_to: Optional[datetime] = None,
) -> str:
    where_sql, params = _build_audit_filters(
        module_name=module_name,
        source=source,
        validated=validated,
        created_from=created_from,
        created_to=created_to,
    )
    result = await session.execute(
        text(
            f"""
            SELECT
                {AUDIT_SELECT_COLUMNS}
            FROM ai_audit_log
            WHERE {' AND '.join(where_sql)}
            ORDER BY created_at DESC
            """
        ),
        params,
    )
    rows = [_serialize_audit_row(row) for row in result.mappings().all()]

    buffer = StringIO()
    csv_writer = writer(buffer)
    csv_writer.writerow(
        [
            "uuid",
            "module_name",
            "source",
            "model",
            "created_at",
            "validated",
            "warnings",
            "validator_messages",
            "review_status",
            "reviewer",
            "reviewed_at",
            "review_note",
            "latency_ms",
            "input_summary",
            "output_summary",
            "context",
        ]
    )
    for row in rows:
        csv_writer.writerow(
            [
                row.get("uuid"),
                row.get("module_name"),
                row.get("source"),
                row.get("model"),
                row.get("created_at"),
                row.get("validated"),
                _csv_value(row.get("warnings")),
                _csv_value(row.get("validator_messages")),
                row.get("review_status"),
                row.get("reviewer"),
                row.get("reviewed_at"),
                row.get("review_note"),
                row.get("latency_ms"),
                row.get("input_summary"),
                row.get("output_summary"),
                _csv_value(row.get("context")),
            ]
        )
    return buffer.getvalue()


def _build_audit_filters(
    *,
    module_name: Optional[str] = None,
    source: Optional[str] = None,
    validated: Optional[bool] = None,
    created_from: Optional[datetime] = None,
    created_to: Optional[datetime] = None,
) -> tuple[list[str], dict[str, Any]]:
    where_sql = ["1 = 1"]
    params: dict[str, Any] = {}

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
    return where_sql, params


def _build_audit_summary(row: Optional[dict[str, Any]], items: list[dict[str, Any]]) -> dict[str, int]:
    total_count = _safe_int((row or {}).get("total_count"))
    validated_count = _safe_int((row or {}).get("validated_count"))
    pending_count = _safe_int((row or {}).get("pending_count"))
    review_pending_count = _safe_int((row or {}).get("review_pending_count"))
    review_approved_count = _safe_int((row or {}).get("review_approved_count"))
    review_rejected_count = _safe_int((row or {}).get("review_rejected_count"))

    # Test doubles and degraded queries may not return aggregate aliases.
    if total_count is None:
        total_count = len(items)
    if validated_count is None:
        validated_count = sum(1 for item in items if item.get("validated"))
    if pending_count is None:
        pending_count = max(total_count - validated_count, 0)
    if review_pending_count is None:
        review_pending_count = sum(1 for item in items if item.get("review_status") == REVIEW_PENDING)
    if review_approved_count is None:
        review_approved_count = sum(1 for item in items if item.get("review_status") == REVIEW_APPROVED)
    if review_rejected_count is None:
        review_rejected_count = sum(1 for item in items if item.get("review_status") == REVIEW_REJECTED)

    return {
        "total_count": total_count,
        "validated_count": validated_count,
        "pending_count": pending_count,
        "review_pending_count": review_pending_count,
        "review_approved_count": review_approved_count,
        "review_rejected_count": review_rejected_count,
    }


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
    reviewed_at = row.get("reviewed_at")
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
        "review_status": row.get("review_status") or REVIEW_PENDING,
        "review_note": row.get("review_note"),
        "reviewer": row.get("reviewer"),
        "reviewed_at": reviewed_at.isoformat() if reviewed_at else None,
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


def _safe_int(value: Any) -> Optional[int]:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _csv_value(value: Any) -> str:
    if value in (None, ""):
        return ""
    if isinstance(value, str):
        return value
    return _json_dump(value)
