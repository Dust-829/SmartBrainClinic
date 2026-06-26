
"""
AI 智能分诊 - 多轮对话引擎
支持多轮对话收集患者信息，逐步判断科室。
返回中包含 dept_determined 标志，便于前端判断是否已得出科室。
"""

import logging
from typing import Dict, Any, List
from app.common.ai_audit import (
    elapsed_ms,
    record_ai_audit,
    redact_sensitive_data,
    start_ai_timer,
)
from app.common.ai_client import AIClient
from app.common.ai_reviewer import review_triage_result
from app.common.ai_schema import AISource, TriageResultData, build_ai_result
from app.common.ai_validator import AIResultValidator, AIValidationResult
from app.common.clients import AuthClient
from app.microservices.patient.config import PatientSettings

logger = logging.getLogger("patient.ai_triage")

# 支持的标准科室对照表
DEPT_MAP = {
    "SJWK": "神经外科",
    "XNK": "心内科",
    "GK": "骨科",
    "EK": "儿科",
    "FCK": "妇产科",
}

DEPT_LIST = [{"code": k, "name": v} for k, v in DEPT_MAP.items()]

MAX_TRIAGE_RECENT_MESSAGES = 6
MAX_TRIAGE_MEMORY_CHARS = 700
MAX_TRIAGE_MESSAGE_CHARS = 500

SYSTEM_PROMPT = (
    "你是医院AI分诊助手，只负责收集症状并推荐就诊科室。"
    "信息不足时追问主要症状、部位、持续时间、过敏史、既往史，每次最多问1-2个问题。"
    "禁止诊断、用药、开检查、给治疗方案。"
    "若有胸痛、呼吸困难、意识不清、大出血、自杀等急症风险，应提示急诊/120。"
    "只能推荐这些科室代码：SJWK(神经外科), XNK(心内科), GK(骨科), EK(儿科), FCK(妇产科)。"
    "信息不足时 dept_determined=false 且 recommended_dept_code=null；"
    "能判断科室时 dept_determined=true 且填写代码，后续对话除非新信息明显推翻，否则保持该科室。"
    "symptom_summary 要持续融合已知症状、部位、持续时间、过敏史、既往史。"
    "gender_preference 只能是 男、女、不限；妇产科默认女，患者明确偏好时按患者偏好，否则不限。"
    "必须只返回原始JSON，不要Markdown，不要额外文字。格式：\n"
    "{"
    '  "reply": "你要对患者说的话（中文）",\n'
    '  "dept_determined": false或true,\n'
    '  "recommended_dept_code": null或科室代码字符串,\n'
    '  "symptom_summary": "从对话中提炼的核心症状摘要（用于后续医生推荐的语义匹配），如果信息不足则填null",\n'
    '  "gender_preference": "根据症状或患者表述判断的医生性别倾向，只能填 男、女 或 不限，默认不限"\n'
    "}"
)

async def run_ai_triage(
    messages: List[Dict[str, str]],
    api_key: str = None,
    api_base: str = None,
    model: str = None,
) -> Dict[str, Any]:
    """
    多轮对话分诊。
    messages: 前端传入的对话历史，格式为 [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}, ...]
    返回: {"reply": "...", "dept_determined": bool, "recommended_dept_code": str|null}
    """
    started_at = start_ai_timer()
    settings = PatientSettings()
    api_key = api_key or settings.LLM_API_KEY
    api_base = api_base or settings.LLM_API_BASE
    model = model or getattr(settings, "LLM_MODEL", "deepseek-ai/DeepSeek-V4-Flash")

    # 1. 尝试真实大模型
    if api_key and api_key.strip():
        logger.info("🤖 [AI Triage] Invoking real LLM for multi-turn triage...")
        try:
            full_messages = _build_triage_llm_messages(messages)

            data = await AIClient(api_key=api_key, api_base=api_base).chat_json(
                model=model,
                messages=full_messages,
                temperature=0.3,
                timeout=10.0,
            )
            if data:
                # 校验科室代码合法性
                dept_code = data.get("recommended_dept_code")
                if dept_code and dept_code not in DEPT_MAP:
                    data["recommended_dept_code"] = None
                    data["dept_determined"] = False
                data = TriageResultData(**data).model_dump(mode="json")
                data, validation, confidence = await _apply_triage_trust_controls(
                    data,
                    messages,
                    source=AISource.LLM,
                    api_key=api_key,
                    api_base=api_base,
                    model=model,
                )

                logger.info(f"✅ [AI Triage] LLM response: {data}")
                result = build_ai_result(
                    data,
                    source=AISource.LLM,
                    model=model,
                    confidence=confidence,
                    **validation.as_result_kwargs(),
                )
                await record_ai_audit(
                    module_name="patient.triage",
                    input_text=messages,
                    result=result,
                    latency_ms=elapsed_ms(started_at),
                )
                return result
        except Exception as e:
            logger.error(f"⚠️ [AI Triage] LLM invocation failed: {e}. Falling back to Mock...")

    # 2. Mock 多轮对话引擎（离线/测试模式）
    logger.info("🔌 [AI Triage] Running offline Mock multi-turn triage engine...")
    data = TriageResultData(**_mock_multi_turn_triage(messages)).model_dump(mode="json")
    data, validation, confidence = await _apply_triage_trust_controls(
        data,
        messages,
        source=AISource.MOCK,
        api_key=api_key,
        api_base=api_base,
        model=model,
    )
    result = build_ai_result(
        data,
        source=AISource.MOCK,
        model="mock-triage",
        confidence=confidence,
        warnings=["using_mock_triage_engine", *validation.warnings],
        validated=validation.is_valid,
        validator_messages=list(validation.messages),
    )
    await record_ai_audit(
        module_name="patient.triage",
        input_text=messages,
        result=result,
        latency_ms=elapsed_ms(started_at),
    )
    return result


def _build_triage_llm_messages(messages: List[Dict[str, str]]) -> list[dict[str, str]]:
    normalized_messages = _normalize_triage_messages(messages)
    recent_messages = normalized_messages[-MAX_TRIAGE_RECENT_MESSAGES:]
    older_messages = normalized_messages[:-MAX_TRIAGE_RECENT_MESSAGES]

    llm_messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    memory = _build_triage_memory(older_messages)
    if memory:
        llm_messages.append(
            {
                "role": "system",
                "content": (
                    "以下是较早对话的压缩记忆，仅作为上下文参考；"
                    "如果和最近对话冲突，以最近对话为准。\n"
                    f"{memory}"
                ),
            }
        )
    llm_messages.extend(recent_messages)
    return llm_messages


def _normalize_triage_messages(messages: List[Dict[str, str]]) -> list[dict[str, str]]:
    normalized: list[dict[str, str]] = []
    for message in messages:
        role = message.get("role") if isinstance(message, dict) else "user"
        content = str(message.get("content") or "") if isinstance(message, dict) else ""
        if role not in {"user", "assistant"}:
            role = "user"
        content = str(redact_sensitive_data(content))
        content = _compact_text(content, MAX_TRIAGE_MESSAGE_CHARS)
        if content:
            normalized.append({"role": role, "content": content})
    return normalized


def _build_triage_memory(messages: list[dict[str, str]]) -> str:
    if not messages:
        return ""

    older_user_text = "；".join(
        message["content"] for message in messages if message["role"] == "user"
    )
    older_assistant_text = "；".join(
        message["content"] for message in messages if message["role"] == "assistant"
    )

    memory_parts: list[str] = []
    if older_user_text:
        memory_parts.append(
            "较早患者表述摘要："
            + _compact_text(older_user_text, MAX_TRIAGE_MEMORY_CHARS)
        )

    dept_hints = _extract_dept_hints(older_assistant_text)
    if dept_hints:
        memory_parts.append("较早科室判断线索：" + "、".join(dept_hints))

    emergency_terms = AIResultValidator.detect_emergency_terms(older_user_text)
    if emergency_terms:
        memory_parts.append("较早急症风险词：" + "、".join(emergency_terms))

    return "\n".join(memory_parts)


def _extract_dept_hints(text: str) -> list[str]:
    hints: list[str] = []
    for code, name in DEPT_MAP.items():
        if code in text or name in text:
            hints.append(f"{code}({name})")
    return hints


def _compact_text(text: str, max_chars: int) -> str:
    compacted = " ".join(str(text or "").split())
    if len(compacted) <= max_chars:
        return compacted
    return compacted[: max_chars - 3] + "..."


async def _apply_triage_trust_controls(
    data: dict[str, Any],
    messages: List[Dict[str, str]],
    *,
    source: AISource,
    api_key: str | None,
    api_base: str | None,
    model: str | None,
) -> tuple[dict[str, Any], AIValidationResult, float]:
    data = dict(data)
    patient_text = _collect_user_text(messages)
    guardrail_warnings: list[str] = []

    precheck = AIResultValidator.secondary_verify_triage(data, patient_text=patient_text)
    if not precheck.is_valid:
        data["reply"] = (
            "您描述的症状可能存在急症风险，请立即前往急诊科就诊，"
            "如症状严重或正在加重，请立刻拨打120。"
        )
        data["dept_determined"] = False
        data["recommended_dept_code"] = None
        data["symptom_summary"] = data.get("symptom_summary") or patient_text[:200] or None
        guardrail_warnings.append("secondary_triage_guardrail_applied")

    dept_exists_in_db = None
    if data.get("dept_determined") and data.get("recommended_dept_code"):
        dept_exists_in_db = await _department_exists_in_db(data["recommended_dept_code"])

    primary = AIResultValidator.validate_triage(
        data,
        allowed_dept_codes=DEPT_MAP.keys(),
        dept_exists_in_db=dept_exists_in_db,
        require_db_fact_check=bool(data.get("dept_determined") and data.get("recommended_dept_code")),
    )
    secondary = AIResultValidator.secondary_verify_triage(data, patient_text=patient_text)
    if guardrail_warnings:
        secondary = AIResultValidator.combine(
            secondary,
            AIValidationResult(True, warnings=tuple(guardrail_warnings)),
        )
    validation = AIResultValidator.combine(primary, secondary)
    confidence = _calculate_triage_confidence(
        data,
        validation=validation,
        patient_text=patient_text,
        source=source,
        dept_exists_in_db=dept_exists_in_db,
    )
    llm_review = await review_triage_result(
        data=data,
        patient_text=patient_text,
        validation=validation,
        confidence=confidence,
        api_key=api_key,
        api_base=api_base,
        model=model,
    )
    validation = AIResultValidator.combine(validation, llm_review)
    confidence = _calculate_triage_confidence(
        data,
        validation=validation,
        patient_text=patient_text,
        source=source,
        dept_exists_in_db=dept_exists_in_db,
    )
    return data, validation, confidence


def _calculate_triage_confidence(
    data: dict[str, Any],
    *,
    validation: AIValidationResult,
    patient_text: str,
    source: AISource,
    dept_exists_in_db: bool | None,
) -> float:
    score = 0.56 if source == AISource.LLM else 0.42

    has_patient_text = len(patient_text.strip()) >= 6
    has_summary = len(str(data.get("symptom_summary") or "").strip()) >= 8
    has_dept = bool(data.get("dept_determined") and data.get("recommended_dept_code"))

    if has_dept:
        score += 0.18
    elif has_patient_text:
        score += 0.04
    else:
        score -= 0.08

    if has_summary:
        score += 0.08

    if _contains_triage_detail(patient_text):
        score += 0.06

    if dept_exists_in_db is True:
        score += 0.08
    elif dept_exists_in_db is False:
        score -= 0.25

    emergency_terms = AIResultValidator.detect_emergency_terms(patient_text)
    if emergency_terms:
        score -= 0.08
        reply = str(data.get("reply") or "")
        if any(term in reply for term in ("急诊", "急救", "120", "立即")):
            score += 0.08

    meaningful_warnings = [
        warning
        for warning in validation.warnings
        if not warning.endswith("_llm_second_review_unavailable")
        and "fact_check_unavailable" not in warning
    ]
    score -= min(0.30, len(validation.messages) * 0.10)
    score -= min(0.15, len(meaningful_warnings) * 0.04)
    if not validation.is_valid:
        score -= 0.12

    return _clamp_confidence(score)


def _contains_triage_detail(text: str) -> bool:
    detail_terms = (
        "天",
        "小时",
        "分钟",
        "部位",
        "左",
        "右",
        "持续",
        "疼",
        "痛",
        "发热",
        "咳嗽",
        "外伤",
        "过敏",
        "病史",
    )
    return any(term in text for term in detail_terms)


def _clamp_confidence(value: float) -> float:
    return round(max(0.05, min(0.95, value)), 2)


def _collect_user_text(messages: List[Dict[str, str]]) -> str:
    return " ".join(
        str(message.get("content") or "")
        for message in messages
        if message.get("role") == "user"
    )


async def _department_exists_in_db(dept_code: str) -> bool | None:
    try:
        return await AuthClient.get_department_by_code(dept_code) is not None
    except Exception as exc:
        logger.warning("[AI Triage] Department fact check unavailable: %s", exc)
        return None


def _mock_multi_turn_triage(messages: List[Dict[str, str]]) -> Dict[str, Any]:
    """
    高保真 Mock 多轮分诊引擎
    """
    # 获取用户的所有发言拼接
    user_texts = " ".join([m["content"] for m in messages if m.get("role") == "user"])
    user_texts_lower = user_texts.lower()

    # 尝试匹配科室
    dept_code = None
    if any(k in user_texts_lower for k in ["头痛", "眩晕", "脑", "昏迷", "颅内", "脑积水", "肿瘤"]):
        dept_code = "SJWK"
    elif any(k in user_texts_lower for k in ["骨折", "摔伤", "关节", "扭伤", "骨头", "外伤"]):
        dept_code = "GK"
    elif any(k in user_texts_lower for k in ["怀孕", "产检", "妇科", "痛经", "阴道"]):
        dept_code = "FCK"
    elif any(k in user_texts_lower for k in ["小儿", "婴儿", "儿童", "小孩", "宝宝"]):
        dept_code = "EK"
    elif any(k in user_texts_lower for k in ["发烧", "咳嗽", "感冒", "流感", "胸闷", "胃痛", "心脏", "心悸"]):
        dept_code = "XNK"

    # 判断用户发言轮数，决定是否继续追问
    user_msg_count = len([m for m in messages if m.get("role") == "user"])

    # 提取症状摘要
    symptom_summary = user_texts.strip() if len(user_texts.strip()) > 2 else None
    
    # 性别倾向推断
    gender_preference = "不限"
    if dept_code == "FCK":
        gender_preference = "女"

    if user_msg_count <= 1 and not dept_code:
        # 第一轮且没有有效信息
        return {
            "reply": "您好！我是AI分诊助手，很高兴为您服务。请问您目前身体哪里不舒服？可以描述一下您的主要症状吗？",
            "dept_determined": False,
            "recommended_dept_code": None,
            "symptom_summary": symptom_summary,
            "gender_preference": gender_preference
        }

    if not dept_code:
        # 多轮了但仍无法判断
        return {
            "reply": "感谢您的描述。为了更准确地帮您分诊，请问您的症状主要集中在身体哪个部位？持续多长时间了？",
            "dept_determined": False,
            "recommended_dept_code": None,
            "symptom_summary": symptom_summary,
            "gender_preference": gender_preference
        }

    # 已经判断出科室
    dept_name = DEPT_MAP.get(dept_code, "")
    return {
        "reply": f"根据您描述的症状，建议您前往{dept_name}就诊。如果您还有其他需要补充的信息，可以继续告诉我。",
        "dept_determined": True,
        "recommended_dept_code": dept_code,
        "symptom_summary": symptom_summary,
        "gender_preference": gender_preference
    }
