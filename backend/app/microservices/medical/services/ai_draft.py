"""
AI medical draft generation engine for the medical microservice.

The input supports both legacy plain conversation payloads and the newer
structured patient triage context envelope returned by
``GET /api/v1/patient/register/{register_uuid}/ai-context``.
"""

import json
import logging
from typing import Any

from app.common.ai_audit import elapsed_ms, record_ai_audit, start_ai_timer
from app.common.ai_client import AIClient
from app.common.ai_schema import AISource, MedicalDraftData, build_ai_result
from app.common.ai_validator import AIResultValidator

logger = logging.getLogger("medical.ai_draft")

SYSTEM_PROMPT = """你是一个专业的电子病历初稿生成AI。你将收到患者基础档案快照、本次AI分诊摘要以及患者与AI分诊助手的对话历史。

【你的任务】
从这些上下文中提取有价值的医学信息，填充到病历初稿的各个字段中。

【核心原则 —— 禁止编造】
1. 只能记录上下文中明确出现过的信息。
2. 基础档案快照只可作为年龄、性别等背景信息，不可据此推断病史。
3. 对于患者未提及的信息，对应字段必须填写"未详细说明"。
4. 禁止根据症状推测诊断结论、用药方案或检查建议。
5. 所有字段均为辅助医生参考的初稿，医生会在此基础上修改确认。

【输出格式要求】
请严格输出一个JSON对象，不要包含任何markdown代码块包裹：
{
  "readme": "主诉：用一句话概括患者的核心症状和持续时间。如果上下文中未提及具体症状，填'未详细说明'",
  "present": "现病史：按时间线整理患者描述的症状发展过程。只记录患者明确说过的内容",
  "history": "既往史：患者提及的既往疾病、手术史等。未提及则填'未详细说明'",
  "allergy": "过敏史：患者提及的药物或食物过敏。未提及则填'未详细说明'",
  "proposal": "初步建议：仅当上下文中有明确线索时给出方向性建议，否则填'待医生问诊后补充'",
  "cure": "处置意见：填'待医生问诊后确定'"
}

请只返回原始JSON字符串，不要有任何额外文字。"""


async def run_ai_medical_draft(
    conversation_json: Any,
    api_key: str = None,
    api_base: str = None,
    model: str = None,
) -> dict[str, Any]:
    """
    Generate a medical draft from either:
    1. legacy conversation history JSON (list of {role, content}), or
    2. a structured triage context envelope.
    """
    from app.microservices.medical.config import settings

    started_at = start_ai_timer()
    api_key = api_key or settings.LLM_API_KEY
    api_base = api_base or settings.LLM_API_BASE
    model = model or getattr(settings, "LLM_MODEL", "deepseek-ai/DeepSeek-V4-Flash")
    audit_input_text = _serialize_for_audit(conversation_json)

    default_draft = {
        "readme": "未详细说明",
        "present": "未详细说明",
        "history": "未详细说明",
        "allergy": "未详细说明",
        "proposal": "待医生问诊后补充",
        "cure": "待医生问诊后确定",
    }

    context, messages = _normalize_draft_context(conversation_json)
    patient_text = _build_patient_text(context, messages)

    if not patient_text:
        logger.info("📝 [AI Draft] No valid draft context, returning blank draft")
        data = MedicalDraftData(**default_draft).model_dump(mode="json")
        validation = AIResultValidator.validate_medical_draft(data)
        result = build_ai_result(
            data,
            source=AISource.FALLBACK,
            model="no-draft-context",
            confidence=0.0,
            warnings=["no_valid_draft_context", *validation.warnings],
            validated=validation.is_valid,
            validator_messages=list(validation.messages),
        )
        await record_ai_audit(
            module_name="medical.draft",
            input_text=audit_input_text,
            result=result,
            latency_ms=elapsed_ms(started_at),
        )
        return result

    if api_key and api_key.strip():
        logger.info("🤖 [AI Draft] Invoking LLM to generate medical record draft...")
        try:
            context_text = _build_draft_context_text(context, messages)
            data = await AIClient(api_key=api_key, api_base=api_base).chat_json(
                model=model,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": (
                            "以下是本次病历初稿可用的上下文，请根据这些信息生成病历初稿。\n\n"
                            f"{context_text}"
                        ),
                    },
                ],
                temperature=0.1,
                timeout=10.0,
            )
            if data:
                for key in default_draft:
                    if key not in data or not data[key]:
                        data[key] = default_draft[key]
                data = MedicalDraftData(**data).model_dump(mode="json")
                validation = AIResultValidator.validate_medical_draft(data)
                result = build_ai_result(
                    data,
                    source=AISource.LLM,
                    model=model,
                    confidence=0.8,
                    **validation.as_result_kwargs(),
                )
                await record_ai_audit(
                    module_name="medical.draft",
                    input_text=audit_input_text,
                    result=result,
                    latency_ms=elapsed_ms(started_at),
                )
                return result
        except Exception as exc:
            logger.error(f"⚠️ [AI Draft] LLM invocation failed: {exc}. Falling back to extraction...")

    logger.info("🔌 [AI Draft] Running offline extraction engine...")
    data = MedicalDraftData(
        **_extract_from_conversation(messages, default_draft, context)
    ).model_dump(mode="json")
    validation = AIResultValidator.validate_medical_draft(data)
    result = build_ai_result(
        data,
        source=AISource.FALLBACK,
        model="rule-draft-extractor",
        confidence=0.5,
        warnings=["using_rule_based_draft_extractor", *validation.warnings],
        validated=validation.is_valid,
        validator_messages=list(validation.messages),
    )
    await record_ai_audit(
        module_name="medical.draft",
        input_text=audit_input_text,
        result=result,
        latency_ms=elapsed_ms(started_at),
    )
    return result


def _normalize_draft_context(raw_payload: Any) -> tuple[dict[str, Any], list[dict[str, str]]]:
    payload = raw_payload
    if isinstance(raw_payload, str):
        try:
            payload = json.loads(raw_payload)
        except (json.JSONDecodeError, TypeError):
            payload = raw_payload

    if isinstance(payload, dict):
        context = {
            "profile_snapshot": payload.get("profile_snapshot"),
            "summary_text": payload.get("summary_text") or _extract_summary_text(payload.get("latest_result")),
            "latest_result": payload.get("latest_result"),
            "fallback_symptoms": payload.get("fallback_symptoms"),
        }
        messages = _normalize_messages(payload.get("messages"))
        if not messages and context["fallback_symptoms"]:
            messages = [{"role": "user", "content": str(context["fallback_symptoms"])}]
        return context, messages

    if isinstance(payload, list):
        return {}, _normalize_messages(payload)

    text = str(payload or "").strip()
    if not text or text == "无":
        return {}, []
    return {"fallback_symptoms": text}, [{"role": "user", "content": text}]


def _normalize_messages(raw_messages: Any) -> list[dict[str, str]]:
    if not isinstance(raw_messages, list):
        return []

    normalized: list[dict[str, str]] = []
    for item in raw_messages:
        if not isinstance(item, dict):
            continue
        content = str(item.get("content") or "").strip()
        if not content:
            continue
        normalized.append(
            {
                "role": str(item.get("role") or "user"),
                "content": content,
            }
        )
    return normalized


def _extract_summary_text(latest_result: Any) -> str | None:
    if not isinstance(latest_result, dict):
        return None
    data = latest_result.get("data")
    if not isinstance(data, dict):
        return None
    summary = data.get("symptom_summary")
    if summary:
        return str(summary)
    return None


def _build_patient_text(context: dict[str, Any], messages: list[dict[str, str]]) -> str:
    parts: list[str] = []

    user_messages = [item.get("content", "").strip() for item in messages if item.get("role") == "user"]
    user_text = " ".join(part for part in user_messages if part)
    if user_text:
        parts.append(user_text)

    summary_text = str(context.get("summary_text") or "").strip()
    if summary_text:
        parts.append(summary_text)

    fallback_symptoms = str(context.get("fallback_symptoms") or "").strip()
    if fallback_symptoms and fallback_symptoms not in parts:
        parts.append(fallback_symptoms)

    return "\n".join(part for part in parts if part).strip()


def _build_draft_context_text(context: dict[str, Any], messages: list[dict[str, str]]) -> str:
    sections: list[str] = []

    profile_snapshot = context.get("profile_snapshot")
    if profile_snapshot:
        sections.append(
            f"【患者基础档案快照】\n{json.dumps(profile_snapshot, ensure_ascii=False, indent=2)}"
        )

    summary_text = str(context.get("summary_text") or "").strip()
    if summary_text:
        sections.append(f"【AI分诊摘要】\n{summary_text}")

    latest_result = context.get("latest_result")
    if latest_result:
        sections.append(
            f"【AI分诊结构化结果】\n{json.dumps(latest_result, ensure_ascii=False, indent=2)}"
        )

    if messages:
        transcript_lines = []
        for msg in messages:
            role_label = "患者" if msg.get("role") == "user" else "AI分诊助手"
            transcript_lines.append(f"{role_label}：{msg.get('content', '')}")
        sections.append("【分诊对话记录】\n" + "\n".join(transcript_lines))
    else:
        fallback_symptoms = str(context.get("fallback_symptoms") or "").strip()
        if fallback_symptoms:
            sections.append(f"【单次挂号症状补充】\n{fallback_symptoms}")

    return "\n\n".join(sections) if sections else "【上下文】\n未提供有效上下文"


def _extract_from_conversation(
    messages: list[dict[str, str]],
    default_draft: dict[str, str],
    context: dict[str, Any] | None = None,
) -> dict[str, str]:
    context = context or {}
    patient_text = _build_patient_text(context, messages)
    draft = dict(default_draft)

    if len(patient_text) > 2:
        first_patient_msg = _first_patient_statement(messages, patient_text)
        draft["readme"] = f"患者自诉：{first_patient_msg[:100]}"
        draft["present"] = f"现病史：患者自诉{patient_text[:200]}。"

    allergy_sources = [item.get("content", "") for item in messages if item.get("role") == "user"]
    if not allergy_sources and patient_text:
        allergy_sources = [patient_text]

    for content in allergy_sources:
        if "过敏" not in content:
            continue
        if any(keyword in content for keyword in ["没有", "无", "否认"]):
            draft["allergy"] = "患者自述无过敏史"
        else:
            draft["allergy"] = f"患者提及过敏相关：{content[:100]}"
        break

    return draft


def _first_patient_statement(messages: list[dict[str, str]], patient_text: str) -> str:
    for item in messages:
        if item.get("role") != "user":
            continue
        content = item.get("content", "").strip()
        if len(content) > 2:
            return content
    return patient_text.strip().splitlines()[0]


def _serialize_for_audit(raw_payload: Any) -> str:
    if isinstance(raw_payload, str):
        return raw_payload
    try:
        return json.dumps(raw_payload, ensure_ascii=False)
    except TypeError:
        return str(raw_payload)
