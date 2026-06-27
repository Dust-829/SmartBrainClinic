"""
Risk-triggered LLM second review for AI-generated medical workflows.

Rules and database facts remain the primary source of truth. The reviewer can
add rejection messages, but it cannot override deterministic validation errors.
"""

import json
import logging
from typing import Any, Iterable, Mapping, Optional

from pydantic import ValidationError

from app.common.ai_audit import redact_sensitive_data
from app.common.ai_client import AIClient
from app.common.ai_schema import AIReviewData
from app.common.ai_validator import AIResultValidator, AIValidationResult
from app.common.config import BaseMicroserviceSettings

logger = logging.getLogger("common.ai_reviewer")

TRIAGE_REVIEW_PROMPT = """
你是医院AI分诊安全审核员，只负责审查AI分诊结果是否安全可靠。
禁止给出诊断、用药、检查或治疗方案。
请基于患者原话、AI分诊输出、规则校验信息进行审核。
如果患者描述存在胸痛、呼吸困难、意识不清、大出血、自杀等急症风险，必须确认AI回复已经引导急诊或120。
只返回原始JSON，不要包含Markdown。
JSON格式:
{
  "approved": true或false,
  "risk_level": "low"或"medium"或"high",
  "reasons": ["中文原因"],
  "suggested_action": "pass"或"escalate_emergency"或"human_review"
}
"""

PRESCRIPTION_REVIEW_PROMPT = """
你是医院临床药师AI审核员，只负责审查AI处方推荐是否安全可靠。
事实源只有: 患者病历摘要、过敏史、规则校验信息、数据库召回药品事实。
禁止推荐数据库药品清单外的药品，禁止忽略过敏冲突、库存不足、重复用药等风险。
只返回原始JSON，不要包含Markdown。
JSON格式:
{
  "approved": true或false,
  "risk_level": "low"或"medium"或"high",
  "reasons": ["中文原因"],
  "suggested_action": "pass"或"reject"或"human_review"
}
"""


async def review_triage_result(
    *,
    data: Mapping[str, Any],
    patient_text: str,
    validation: AIValidationResult,
    confidence: Optional[float] = None,
    api_key: Optional[str] = None,
    api_base: Optional[str] = None,
    model: Optional[str] = None,
    client: Optional[AIClient] = None,
) -> AIValidationResult:
    if not _should_attempt_review():
        return AIValidationResult(True)

    emergency_terms = AIResultValidator.detect_emergency_terms(patient_text)
    should_review = _review_mode() == "always" or (
        not validation.is_valid
        or bool(emergency_terms)
        or (confidence is not None and confidence < 0.5 and bool(data.get("dept_determined")))
    )
    if not should_review:
        return AIValidationResult(True)

    payload = {
        "patient_text": patient_text,
        "triage_result": data,
        "validator_messages": validation.messages,
        "validator_warnings": validation.warnings,
        "confidence": confidence,
        "emergency_terms": emergency_terms,
    }
    return await _call_review_model(
        module_name="triage",
        system_prompt=TRIAGE_REVIEW_PROMPT,
        payload=payload,
        api_key=api_key,
        api_base=api_base,
        model=model,
        client=client,
    )


async def review_prescription_result(
    *,
    recommendations: Iterable[Mapping[str, Any]],
    medical_record: Mapping[str, Any],
    available_drugs: Iterable[Mapping[str, Any]],
    validation: AIValidationResult,
    confidence: Optional[float] = None,
    api_key: Optional[str] = None,
    api_base: Optional[str] = None,
    model: Optional[str] = None,
    client: Optional[AIClient] = None,
) -> AIValidationResult:
    if not _should_attempt_review():
        return AIValidationResult(True)

    recommendations_list = list(recommendations)
    should_review = _review_mode() == "always" or (
        not validation.is_valid
        or _has_prescription_risk_warning(validation.warnings)
        or (confidence is not None and confidence < 0.65 and bool(recommendations_list))
    )
    if not should_review:
        return AIValidationResult(True)

    payload = {
        "medical_record": _compact_medical_record(medical_record),
        "recommendations": recommendations_list,
        "available_drug_facts": _select_recommended_drug_facts(
            recommendations_list,
            available_drugs,
        ),
        "validator_messages": validation.messages,
        "validator_warnings": validation.warnings,
        "confidence": confidence,
    }
    return await _call_review_model(
        module_name="prescription",
        system_prompt=PRESCRIPTION_REVIEW_PROMPT,
        payload=payload,
        api_key=api_key,
        api_base=api_base,
        model=model,
        client=client,
    )


def review_data_to_validation(module_name: str, raw_data: Any) -> AIValidationResult:
    try:
        review = AIReviewData(**raw_data)
    except ValidationError as exc:
        return AIValidationResult(
            True,
            warnings=(f"{module_name}_llm_second_review_schema_invalid: {exc}",),
        )

    reasons = tuple(str(reason) for reason in review.reasons if str(reason).strip())
    reason_text = ";".join(reasons) if reasons else "no_reason"
    if not review.approved or review.suggested_action in {"reject", "human_review"}:
        message = (
            f"{module_name}_llm_second_review_rejected: "
            f"{review.suggested_action}: {reason_text}"
        )
        return AIValidationResult(
            False,
            (message,),
            (f"{module_name}_llm_second_review_risk_level: {review.risk_level}",),
        )

    return AIValidationResult(
        True,
        warnings=(
            f"{module_name}_llm_second_review_approved: "
            f"{review.risk_level}: {review.suggested_action}",
        ),
    )


async def _call_review_model(
    *,
    module_name: str,
    system_prompt: str,
    payload: Mapping[str, Any],
    api_key: Optional[str],
    api_base: Optional[str],
    model: Optional[str],
    client: Optional[AIClient],
) -> AIValidationResult:
    settings = BaseMicroserviceSettings()
    review_model = settings.AI_SECOND_REVIEW_MODEL or model or settings.LLM_MODEL
    ai_client = client or AIClient(api_key=api_key, api_base=api_base)

    if not ai_client.is_configured:
        return AIValidationResult(
            True,
            warnings=(f"{module_name}_llm_second_review_unavailable",),
        )

    try:
        raw_review = await ai_client.chat_json(
            model=review_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": json.dumps(
                        redact_sensitive_data(payload),
                        ensure_ascii=False,
                        default=str,
                    ),
                },
            ],
            temperature=0.0,
            timeout=8.0,
            max_tokens=600,
        )
    except Exception as exc:
        logger.warning("[%s] LLM second review failed: %s", module_name, exc)
        raw_review = None

    if raw_review is None:
        return AIValidationResult(
            True,
            warnings=(f"{module_name}_llm_second_review_unavailable",),
        )

    return review_data_to_validation(module_name, raw_review)


def _should_attempt_review() -> bool:
    return _review_mode() != "off"


def _review_mode() -> str:
    settings = BaseMicroserviceSettings()
    if not settings.AI_SECOND_REVIEW_ENABLED:
        return "off"
    return (settings.AI_SECOND_REVIEW_MODE or "risk_only").strip().lower()


def _has_prescription_risk_warning(warnings: Iterable[str]) -> bool:
    risk_tokens = (
        "allergy_conflict",
        "drug_name_mismatch",
        "stock_insufficient",
        "not_found_in_db",
    )
    return any(any(token in warning for token in risk_tokens) for warning in warnings)


def _compact_medical_record(record: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "diagnosis": record.get("diagnosis"),
        "readme": record.get("readme"),
        "present": record.get("present"),
        "history": record.get("history"),
        "allergy": record.get("allergy"),
    }


def _select_recommended_drug_facts(
    recommendations: Iterable[Mapping[str, Any]],
    available_drugs: Iterable[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    recommended_ids: set[int] = set()
    for item in recommendations:
        drug_id = _to_int(item.get("drug_id"))
        if drug_id is not None:
            recommended_ids.add(drug_id)
    facts: list[dict[str, Any]] = []
    for drug in available_drugs:
        drug_id = _to_int(drug.get("id"))
        if drug_id in recommended_ids:
            facts.append(
                {
                    "id": drug.get("id"),
                    "drug_name": drug.get("drug_name"),
                    "specification": drug.get("specification"),
                    "unit": drug.get("unit"),
                    "stock": drug.get("stock"),
                }
            )
    return facts


def _to_int(value: Any) -> Optional[int]:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None
