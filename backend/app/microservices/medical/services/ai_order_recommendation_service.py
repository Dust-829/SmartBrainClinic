"""Read-only assembly of doctor-facing AI order recommendation context."""

from __future__ import annotations

import uuid as uuid_pkg
from collections.abc import Mapping
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.clients import PatientClient

from ..models.medical import CheckRequest, InspectionRequest, MedicalRecord, MedicalTechnology
from .ai_order_recommendation import build_rule_order_candidates


async def recommend_order_candidates(session: AsyncSession, register_uuid: uuid_pkg.UUID | str) -> dict[str, Any]:
    """Build temporary candidates without creating medical requests or audit records."""

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

    candidates = build_rule_order_candidates(
        clinical_text=_build_clinical_text(record, triage_context),
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
    if not candidates:
        warnings.append("no_safe_catalog_candidate")

    return {
        "items": candidates,
        "source": "record_catalog_rule",
        "triage_context_used": triage_context is not None,
        "warnings": warnings,
    }


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
