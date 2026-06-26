"""
Best-effort AI audit logging.

The audit writer records AI module, source, model, compact input/output
summaries, warnings, validator messages, and latency. Failures are logged but
never raised, so audit persistence cannot break business workflows.
"""

import json
import logging
import time
import uuid
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine

from app.common.config import BaseMicroserviceSettings

logger = logging.getLogger("common.ai_audit")

_engine: Optional[AsyncEngine] = None
_table_ready = False


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
        await _ensure_table(engine)

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


def _get_engine() -> AsyncEngine:
    global _engine
    if _engine is None:
        settings = BaseMicroserviceSettings()
        _engine = create_async_engine(settings.get_db_url(), echo=False)
    return _engine


async def _ensure_table(engine: AsyncEngine) -> None:
    global _table_ready
    if _table_ready:
        return

    async with engine.begin() as conn:
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS ai_audit_log (
                    id BIGSERIAL PRIMARY KEY,
                    uuid UUID NOT NULL,
                    module_name VARCHAR(128) NOT NULL,
                    source VARCHAR(32),
                    model VARCHAR(128),
                    input_summary TEXT,
                    output_summary TEXT,
                    warnings TEXT,
                    validated BOOLEAN DEFAULT FALSE,
                    validator_messages TEXT,
                    latency_ms INTEGER,
                    context TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(
            text(
                """
                CREATE INDEX IF NOT EXISTS idx_ai_audit_log_module_created
                ON ai_audit_log (module_name, created_at DESC)
                """
            )
        )
    _table_ready = True


def _summarize(value: Any, max_len: int = 1000) -> str:
    if isinstance(value, str):
        text_value = value
    else:
        text_value = _json_dump(value)
    return text_value[:max_len]


def _json_dump(value: Any) -> str:
    try:
        return json.dumps(value, ensure_ascii=False, default=str)
    except TypeError:
        return str(value)
