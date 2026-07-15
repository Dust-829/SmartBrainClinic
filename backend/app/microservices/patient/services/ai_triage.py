"""
患者端 AI 分诊服务。
负责多轮症状采集、科室推荐、分诊可信度评估、审计记录与二次校验。
"""

import logging
from typing import Any, Dict, List

from app.common.ai_audit import elapsed_ms, record_ai_audit, redact_sensitive_data, start_ai_timer
from app.common.ai_client import AIClient
from app.common.ai_reviewer import review_triage_result
from app.common.ai_schema import AISource, TriageResultData, build_ai_result
from app.common.ai_validator import AIResultValidator, AIValidationResult
from app.common.clients import AuthClient
from app.microservices.patient.config import PatientSettings

logger = logging.getLogger('patient.ai_triage')


class TriageAIUnavailableError(RuntimeError):
    """Raised when real AI triage configuration is missing or invalid."""


DEPT_MAP = {
    'SJWK': '神经外科',
    'XNK': '心内科',
    'GK': '骨科',
    'EK': '儿科',
    'FCK': '妇产科',
}

DEPT_LIST = [{'code': code, 'name': name} for code, name in DEPT_MAP.items()]

MAX_TRIAGE_RECENT_MESSAGES = 6
MAX_TRIAGE_MEMORY_CHARS = 700
MAX_TRIAGE_MESSAGE_CHARS = 500

SYSTEM_PROMPT = """
你是医院分诊助手，只负责收集症状并推荐就诊科室。

规则：
1. 只能在以下科室代码中选择：SJWK(神经外科)、XNK(心内科)、GK(骨科)、EK(儿科)、FCK(妇产科)。
2. 如果用户明确在问“挂什么科”“挂哪科”“看什么科”，且当前症状或疾病已经足以对应某个科室，则直接给出科室，不要先追问年龄、性别或既往史。
3. 常见直接分诊线索：高血压、血压高、心慌、心悸、胸痛、胸闷优先推荐 XNK；头痛、眩晕、脑部、昏迷优先推荐 SJWK；骨折、摔伤、扭伤优先推荐 GK；婴儿、儿童优先推荐 EK；怀孕、产检、痛经、阴道出血优先推荐 FCK。
4. 只有在现有信息仍无法落到以上 5 个科室之一时，才继续追问，每次最多追问 1 到 2 个问题。
5. 禁止直接给出诊断、处方、检查单和治疗方案。
6. 若用户描述胸痛、呼吸困难、意识不清、大出血、自杀倾向等急症风险，应明确提示立即前往急诊或拨打 120。
7. 若科室无法确定，必须返回 dept_determined=false 且 recommended_dept_code=null。
8. 若科室可以确定，返回 dept_determined=true 并填写推荐科室代码。
9. symptom_summary 要尽量整合主诉、部位、持续时间、伴随症状、既往史。
10. gender_preference 只能填写：男、女、不限；妇产科默认女，其余情况默认不限。
11. 只返回 JSON，不要返回 Markdown，不要返回额外解释。

返回格式：
{
  "reply": "你要对患者说的话",
  "dept_determined": false,
  "recommended_dept_code": null,
  "symptom_summary": "症状摘要，可为空",
  "gender_preference": "不限"
}
""".strip()


async def run_ai_triage(
    messages: List[Dict[str, str]],
    profile_snapshot: Dict[str, Any] | None = None,
    api_key: str | None = None,
    api_base: str | None = None,
    model: str | None = None,
) -> Dict[str, Any]:
    """执行患者端多轮 AI 分诊。"""
    started_at = start_ai_timer()
    settings = PatientSettings()
    api_key = api_key or settings.LLM_API_KEY
    api_base = api_base or settings.LLM_API_BASE
    model = model or getattr(settings, 'LLM_MODEL', 'deepseek-ai/DeepSeek-V4-Flash')
    allow_mock_fallback = bool(settings.AI_ALLOW_MOCK_FALLBACK and settings.APP_ENV != 'production')

    if not api_key or not api_key.strip():
        if not allow_mock_fallback:
            logger.warning('[AI Triage] LLM_API_KEY missing, switching to deterministic fallback triage.')
            return await _build_rule_fallback_result(
                messages,
                started_at=started_at,
                api_key=api_key,
                api_base=api_base,
                model=model,
                warning='llm_triage_not_configured_fallback',
            )
        logger.warning('[AI Triage] LLM_API_KEY missing, falling back to mock triage engine.')
    else:
        logger.info('[AI Triage] Invoking real LLM for multi-turn triage.')
        try:
            full_messages = _build_triage_llm_messages(messages, profile_snapshot=profile_snapshot)
            data = await AIClient(api_key=api_key, api_base=api_base).chat_json(
                model=model,
                messages=full_messages,
                temperature=0.3,
                timeout=20.0,
                response_format={"type": "json_object"},
                retries=1,
            )
            if data:
                dept_code = data.get('recommended_dept_code')
                if dept_code and dept_code not in DEPT_MAP:
                    data['recommended_dept_code'] = None
                    data['dept_determined'] = False

                data = TriageResultData(**data).model_dump(mode='json')
                fallback_candidate = _mock_multi_turn_triage(messages)
                if _should_use_rule_fallback(data, fallback_candidate, messages):
                    logger.warning('[AI Triage] LLM returned low-quality triage result, switching to rule fallback.')
                    fallback_data = TriageResultData(**fallback_candidate).model_dump(mode='json')
                    fallback_data, validation, confidence = await _apply_triage_trust_controls(
                        fallback_data,
                        messages,
                        source=AISource.FALLBACK,
                        api_key=api_key,
                        api_base=api_base,
                        model=model,
                    )
                    result = build_ai_result(
                        fallback_data,
                        source=AISource.FALLBACK,
                        model='llm-rule-fallback',
                        confidence=confidence,
                        warnings=['llm_triage_low_quality_fallback', *validation.warnings],
                        validated=validation.is_valid,
                        validator_messages=list(validation.messages),
                    )
                    await record_ai_audit(
                        module_name='patient.triage',
                        input_text=messages,
                        result=result,
                        latency_ms=elapsed_ms(started_at),
                    )
                    return result

                data, validation, confidence = await _apply_triage_trust_controls(
                    data,
                    messages,
                    source=AISource.LLM,
                    api_key=api_key,
                    api_base=api_base,
                    model=model,
                )
                result = build_ai_result(
                    data,
                    source=AISource.LLM,
                    model=model,
                    confidence=confidence,
                    **validation.as_result_kwargs(),
                )
                await record_ai_audit(
                    module_name='patient.triage',
                    input_text=messages,
                    result=result,
                    latency_ms=elapsed_ms(started_at),
                )
                return result
        except Exception as exc:
            logger.error('[AI Triage] LLM invocation failed: %s', exc)
            if not allow_mock_fallback:
                return await _build_rule_fallback_result(
                    messages,
                    started_at=started_at,
                    api_key=api_key,
                    api_base=api_base,
                    model=model,
                    warning='llm_triage_request_failed_fallback',
                )

    if not allow_mock_fallback:
        return await _build_rule_fallback_result(
            messages,
            started_at=started_at,
            api_key=api_key,
            api_base=api_base,
            model=model,
            warning='llm_triage_no_valid_result_fallback',
        )

    logger.info('[AI Triage] Running offline mock triage engine.')
    data = TriageResultData(**_mock_multi_turn_triage(messages)).model_dump(mode='json')
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
        model='mock-triage',
        confidence=confidence,
        warnings=['using_mock_triage_engine', *validation.warnings],
        validated=validation.is_valid,
        validator_messages=list(validation.messages),
    )
    await record_ai_audit(
        module_name='patient.triage',
        input_text=messages,
        result=result,
        latency_ms=elapsed_ms(started_at),
    )
    return result


def _build_triage_llm_messages(
    messages: List[Dict[str, str]],
    *,
    profile_snapshot: Dict[str, Any] | None = None,
) -> list[dict[str, str]]:
    normalized_messages = _normalize_triage_messages(messages)
    recent_messages = normalized_messages[-MAX_TRIAGE_RECENT_MESSAGES:]
    older_messages = normalized_messages[:-MAX_TRIAGE_RECENT_MESSAGES]

    llm_messages = [{'role': 'system', 'content': SYSTEM_PROMPT}]
    profile_context = _build_triage_profile_context(profile_snapshot)
    if profile_context:
        llm_messages.append({'role': 'system', 'content': profile_context})
    memory = _build_triage_memory(older_messages)
    if memory:
        llm_messages.append(
            {
                'role': 'system',
                'content': '以下是较早对话的压缩摘要，仅用于补充上下文；如果与最近对话冲突，以最近对话为准。\n' + memory,
            }
        )
    llm_messages.extend(recent_messages)
    return llm_messages


def _build_triage_profile_context(profile_snapshot: Dict[str, Any] | None) -> str:
    if not isinstance(profile_snapshot, dict):
        return ''

    gender = str(profile_snapshot.get('gender') or '').strip()
    age = profile_snapshot.get('age')
    if not gender or not isinstance(age, int) or age < 0:
        return ''

    return (
        f'当前患者基础档案已确认：性别为{gender}，年龄为{age}岁。'
        '这是系统已提供的信息，不要再次询问患者年龄或性别；仅追问缺失的症状细节。'
    )


def _normalize_triage_messages(messages: List[Dict[str, str]]) -> list[dict[str, str]]:
    normalized: list[dict[str, str]] = []
    for message in messages:
        role = message.get('role') if isinstance(message, dict) else 'user'
        content = str(message.get('content') or '') if isinstance(message, dict) else ''
        if role not in {'user', 'assistant'}:
            role = 'user'
        content = str(redact_sensitive_data(content))
        content = _compact_text(content, MAX_TRIAGE_MESSAGE_CHARS)
        if content:
            normalized.append({'role': role, 'content': content})
    return normalized


def _build_triage_memory(messages: list[dict[str, str]]) -> str:
    if not messages:
        return ''

    older_user_text = '；'.join(message['content'] for message in messages if message['role'] == 'user')
    older_assistant_text = '；'.join(message['content'] for message in messages if message['role'] == 'assistant')

    memory_parts: list[str] = []
    if older_user_text:
        memory_parts.append('较早患者主诉摘要：' + _compact_text(older_user_text, MAX_TRIAGE_MEMORY_CHARS))

    dept_hints = _extract_dept_hints(older_assistant_text)
    if dept_hints:
        memory_parts.append('较早科室判断线索：' + '、'.join(dept_hints))

    emergency_terms = AIResultValidator.detect_emergency_terms(older_user_text)
    if emergency_terms:
        memory_parts.append('较早急症风险词：' + '、'.join(emergency_terms))

    return '\n'.join(memory_parts)


def _extract_dept_hints(text: str) -> list[str]:
    hints: list[str] = []
    for code, name in DEPT_MAP.items():
        if code in text or name in text:
            hints.append(f'{code}({name})')
    return hints


def _compact_text(text: str, max_chars: int) -> str:
    compacted = ' '.join(str(text or '').split())
    if len(compacted) <= max_chars:
        return compacted
    return compacted[: max_chars - 3] + '...'


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
        data['reply'] = '您描述的情况可能存在急症风险，请立即前往急诊就诊；如症状严重或持续加重，请立刻拨打 120。'
        data['dept_determined'] = False
        data['recommended_dept_code'] = None
        data['symptom_summary'] = data.get('symptom_summary') or patient_text[:200] or None
        guardrail_warnings.append('secondary_triage_guardrail_applied')

    dept_exists_in_db = None
    if data.get('dept_determined') and data.get('recommended_dept_code'):
        dept_exists_in_db = await _department_exists_in_db(data['recommended_dept_code'])

    primary = AIResultValidator.validate_triage(
        data,
        allowed_dept_codes=DEPT_MAP.keys(),
        dept_exists_in_db=dept_exists_in_db,
        require_db_fact_check=bool(data.get('dept_determined') and data.get('recommended_dept_code')),
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
    has_summary = len(str(data.get('symptom_summary') or '').strip()) >= 8
    has_dept = bool(data.get('dept_determined') and data.get('recommended_dept_code'))

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
        reply = str(data.get('reply') or '')
        if any(term in reply for term in ('急诊', '急救', '120', '立即')):
            score += 0.08

    meaningful_warnings = [
        warning
        for warning in validation.warnings
        if not warning.endswith('_llm_second_review_unavailable') and 'fact_check_unavailable' not in warning
    ]
    score -= min(0.30, len(validation.messages) * 0.10)
    score -= min(0.15, len(meaningful_warnings) * 0.04)
    if not validation.is_valid:
        score -= 0.12

    return _clamp_confidence(score)


def _contains_triage_detail(text: str) -> bool:
    detail_terms = (
        '天',
        '小时',
        '分钟',
        '部位',
        '左',
        '右',
        '持续',
        '痛',
        '麻',
        '发热',
        '咳嗽',
        '外伤',
        '过敏',
        '病史',
    )
    return any(term in text for term in detail_terms)


def _is_department_selection_query(text: str) -> bool:
    normalized = str(text or '').strip()
    if not normalized:
        return False

    query_markers = (
        '挂什么科',
        '挂哪科',
        '挂什么科室',
        '看什么科',
        '看哪科',
        '去什么科',
        '推荐科室',
    )
    return any(marker in normalized for marker in query_markers)


def _clamp_confidence(value: float) -> float:
    return round(max(0.05, min(0.95, value)), 2)


def _collect_user_text(messages: List[Dict[str, str]]) -> str:
    return ' '.join(str(message.get('content') or '') for message in messages if message.get('role') == 'user')


async def _department_exists_in_db(dept_code: str) -> bool | None:
    try:
        return await AuthClient.get_department_by_code(dept_code) is not None
    except Exception as exc:
        logger.warning('[AI Triage] Department fact check unavailable: %s', exc)
        return None


async def _build_rule_fallback_result(
    messages: List[Dict[str, str]],
    *,
    started_at,
    api_key: str | None,
    api_base: str | None,
    model: str | None,
    warning: str,
) -> dict[str, Any]:
    fallback_data = TriageResultData(**_mock_multi_turn_triage(messages)).model_dump(mode='json')
    fallback_data, validation, confidence = await _apply_triage_trust_controls(
        fallback_data,
        messages,
        source=AISource.FALLBACK,
        api_key=api_key,
        api_base=api_base,
        model=model,
    )
    result = build_ai_result(
        fallback_data,
        source=AISource.FALLBACK,
        model='rule-triage-fallback',
        confidence=confidence,
        warnings=[warning, *validation.warnings],
        validated=validation.is_valid,
        validator_messages=list(validation.messages),
    )
    await record_ai_audit(
        module_name='patient.triage',
        input_text=messages,
        result=result,
        latency_ms=elapsed_ms(started_at),
    )
    return result


def _should_use_rule_fallback(
    llm_data: dict[str, Any],
    fallback_candidate: dict[str, Any],
    messages: List[Dict[str, str]],
) -> bool:
    if llm_data.get('dept_determined'):
        return False
    if not fallback_candidate.get('dept_determined'):
        return False

    patient_text = _collect_user_text(messages)
    is_department_query = _is_department_selection_query(patient_text)
    if not _contains_triage_detail(patient_text) and not is_department_query:
        return False
    if is_department_query:
        return True

    reply = str(llm_data.get('reply') or '')
    summary = str(llm_data.get('symptom_summary') or '').strip()
    fallback_summary = str(fallback_candidate.get('symptom_summary') or '').strip()
    generic_markers = (
        '没有理解',
        '请您用文字说明',
        '请描述',
        '哪里不舒服',
        '持续多久',
        '伴随症状',
    )

    return (not summary and bool(fallback_summary)) or any(marker in reply for marker in generic_markers)


def _mock_multi_turn_triage(messages: List[Dict[str, str]]) -> Dict[str, Any]:
    user_texts = ' '.join([message['content'] for message in messages if message.get('role') == 'user'])
    user_texts_lower = user_texts.lower()

    dept_code = None
    if any(keyword in user_texts_lower for keyword in ['头痛', '眩晕', '脑', '昏迷', '颅内', '积水', '肿瘤']):
        dept_code = 'SJWK'
    elif any(keyword in user_texts_lower for keyword in ['骨折', '摔伤', '关节', '扭伤', '骨头', '外伤']):
        dept_code = 'GK'
    elif any(keyword in user_texts_lower for keyword in ['怀孕', '产检', '妇科', '痛经', '阴道']):
        dept_code = 'FCK'
    elif any(keyword in user_texts_lower for keyword in ['小儿', '婴儿', '儿童', '小孩', '宝宝']):
        dept_code = 'EK'
    elif any(
        keyword in user_texts_lower
        for keyword in [
            '发热',
            '咳嗽',
            '感冒',
            '流感',
            '胸闷',
            '胃痛',
            '心脏',
            '心慌',
            '高血压',
            '血压高',
            '血压偏高',
            '低血压',
            '心悸',
            '心率',
            '胸痛',
        ]
    ):
        dept_code = 'XNK'

    user_msg_count = len([message for message in messages if message.get('role') == 'user'])
    symptom_summary = user_texts.strip() if len(user_texts.strip()) > 2 else None

    gender_preference = '不限'
    if dept_code == 'FCK':
        gender_preference = '女'

    if user_msg_count <= 1 and not dept_code:
        return {
            'reply': '您好，我是智能分诊助手。请描述一下目前最主要的不适部位、持续时间和伴随症状。',
            'dept_determined': False,
            'recommended_dept_code': None,
            'symptom_summary': symptom_summary,
            'gender_preference': gender_preference,
        }

    if not dept_code:
        return {
            'reply': '为了更准确推荐科室，请再补充症状所在部位、持续时间，以及是否伴随发热、恶心、外伤或既往病史。',
            'dept_determined': False,
            'recommended_dept_code': None,
            'symptom_summary': symptom_summary,
            'gender_preference': gender_preference,
        }

    dept_name = DEPT_MAP.get(dept_code, '')
    return {
        'reply': f'根据您当前描述的症状，建议优先前往{dept_name}就诊。如有新的症状变化，也可以继续补充。',
        'dept_determined': True,
        'recommended_dept_code': dept_code,
        'symptom_summary': symptom_summary,
        'gender_preference': gender_preference,
    }
