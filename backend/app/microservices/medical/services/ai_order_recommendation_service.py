"""Read-only assembly of doctor-facing AI order recommendation context."""

from __future__ import annotations

import uuid as uuid_pkg
from collections.abc import Mapping
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.clients import PatientClient
from app.common.ai_audit import elapsed_ms, record_ai_audit, start_ai_timer
from app.common.ai_client import AIClient
from app.common.ai_schema import AISource, build_ai_result

from ..config import settings
from ..models.medical import CheckRequest, InspectionRequest, MedicalRecord, MedicalTechnology
from .ai_order_recommendation import build_rule_order_candidates, select_validated_llm_order_candidates


_ORDER_RANKING_PROMPT = """
You are a clinical decision-support ranking assistant. You must not diagnose,
prescribe, create orders, or add items. Rank only the supplied candidate IDs.
Return JSON only in this exact shape:
{"items":[{"medical_technology_id":123,"reason":"Concise Chinese rationale for doctor review."}]}
Every item ID must come from the supplied candidate list. Do not output prices,
types, check positions, check purposes, diagnoses, or any other fields.
""".strip()


async def recommend_order_candidates(session: AsyncSession, register_uuid: uuid_pkg.UUID | str) -> dict[str, Any]:
    """Build temporary candidates without creating medical requests or orders."""

    normalized_register_uuid = uuid_pkg.UUID(str(register_uuid))
    record = (
        await session.execute(
            select(MedicalRecord).where(MedicalRecord.register_uuid == normalized_register_uuid)
        )
    ).scalar_one_or_none()
    if not record:
        raise ValueError("未找到该挂号对应的病历")
    if not record.is_doctor_confirmed:
        raise ValueError("请先由医生确认病历后再生成检查检验建议")

    technologies = list(
        (
            await session.execute(
                select(MedicalTechnology)
                .where(
                    MedicalTechnology.delmark == 1,
                    MedicalTechnology.tech_type.in_(("check", "inspection")),
                )
                .order_by(MedicalTechnology.id.asc())
            )
        ).scalars().all()
    )
    ordered_technology_ids = {
        *(
            await session.execute(
                select(CheckRequest.medical_technology_id).where(
                    CheckRequest.register_uuid == normalized_register_uuid
                )
            )
        ).scalars().all(),
        *(
            await session.execute(
                select(InspectionRequest.medical_technology_id).where(
                    InspectionRequest.register_uuid == normalized_register_uuid
                )
            )
        ).scalars().all(),
    }

    warnings: list[str] = []
    triage_context: Mapping[str, Any] | None = None
    try:
        context = await PatientClient.get_register_ai_context(normalized_register_uuid)
        triage_context = context if isinstance(context, Mapping) else None
        if triage_context is None:
            warnings.append("triage_context_unavailable")
    except Exception:
        warnings.append("triage_context_unavailable")

    clinical_text = _build_clinical_text(record, triage_context)
    rule_candidates = build_rule_order_candidates(
        clinical_text=clinical_text,
        technologies=[
            {
                "id": item.id,
                "tech_code": item.tech_code,
                "tech_name": item.tech_name,
                "tech_type": item.tech_type,
                "price": item.price,
            }
            for item in technologies
        ],
        ordered_technology_ids=ordered_technology_ids,
    )
    candidates, source, ranking_warnings = await _rank_rule_candidates_with_llm(
        clinical_text=clinical_text,
        rule_candidates=rule_candidates,
    )
    warnings.extend(ranking_warnings)
    if not candidates:
        warnings.append("no_safe_catalog_candidate")

    return {
        "items": candidates,
        "source": source,
        "triage_context_used": triage_context is not None,
        "warnings": warnings,
    }


async def _rank_rule_candidates_with_llm(
    *,
    clinical_text: str,
    rule_candidates: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], str, list[str]]:
    """Use the LLM only to rank server-generated candidates and explain the ranking."""

    if not rule_candidates:
        return [], "record_catalog_rule", []

    api_key = settings.LLM_API_KEY
    api_base = settings.LLM_API_BASE
    model = settings.LLM_MODEL
    if not api_key or not api_key.strip():
        return rule_candidates, "record_catalog_rule", ["llm_order_not_configured_fallback"]

    started_at = start_ai_timer()
    warnings: list[str] = []
    try:
        llm_data = await AIClient(api_key=api_key, api_base=api_base).chat_json(
            model=model,
            messages=[
                {"role": "system", "content": _ORDER_RANKING_PROMPT},
                {"role": "user", "content": _build_order_ranking_context(clinical_text, rule_candidates)},
            ],
            temperature=0.1,
            timeout=12.0,
            response_format={"type": "json_object"},
            retries=1,
        )
        llm_items = llm_data.get("items") if isinstance(llm_data, Mapping) else None
        candidates, validation_warnings = select_validated_llm_order_candidates(
            rule_candidates=rule_candidates,
            llm_items=llm_items,
        )
        warnings.extend(validation_warnings)
        used_llm = "llm_order_no_valid_result_fallback" not in validation_warnings
        source = "llm_catalog_validated" if used_llm else "record_catalog_rule"
    except Exception:
        candidates = rule_candidates
        source = "record_catalog_rule"
        warnings.append("llm_order_request_failed_fallback")

    audit_result = build_ai_result(
        candidates,
        source=AISource.LLM if source == "llm_catalog_validated" else AISource.RULE,
        model=model if source == "llm_catalog_validated" else "rule-order-catalog",
        confidence=0.8 if source == "llm_catalog_validated" else 0.6,
        warnings=warnings,
        validated=source == "llm_catalog_validated" and not warnings,
        validator_messages=warnings,
    )
    await record_ai_audit(
        module_name="medical.order_recommendation",
        input_text={
            "clinical_text": clinical_text[:2000],
            "candidate_ids": [item["medical_technology_id"] for item in rule_candidates],
        },
        result=audit_result,
        latency_ms=elapsed_ms(started_at),
    )
    return candidates, source, warnings


def _build_order_ranking_context(clinical_text: str, rule_candidates: list[dict[str, Any]]) -> str:
    return (
        "Clinical context (for doctor-support ranking only):\n"
        f"{clinical_text[:2000]}\n\n"
        "Server-approved candidate list:\n"
        f"{[{key: item.get(key) for key in ('medical_technology_id', 'tech_name', 'type')} for item in rule_candidates]}"
    )


def _build_clinical_text(record: MedicalRecord, triage_context: Mapping[str, Any] | None) -> str:
    parts = [
        record.readme,
        record.present,
        record.history,
        record.physique,
        record.diagnosis,
        record.proposal,
    ]
    if triage_context:
        parts.append(triage_context.get("summary_text"))
        latest_result = triage_context.get("latest_result")
        if isinstance(latest_result, Mapping):
            parts.extend(str(value) for value in latest_result.values() if value)
        messages = triage_context.get("messages")
        if isinstance(messages, list):
            parts.extend(
                str(message.get("content"))
                for message in messages
                if isinstance(message, Mapping) and message.get("content")
            )
    return "\n".join(str(value).strip() for value in parts if value and str(value).strip())
