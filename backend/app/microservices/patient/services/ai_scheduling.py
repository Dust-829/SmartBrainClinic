"""AI scheduling parsing and fallback helpers."""

from __future__ import annotations

import logging
import re
from datetime import date, timedelta
from typing import Any, Optional

from app.common.ai_audit import elapsed_ms, record_ai_audit, start_ai_timer
from app.common.ai_client import AIClient
from app.common.ai_schema import AISource, SchedulingParseData, build_ai_result
from app.common.ai_validator import AIResultValidator

from ..config import settings

logger = logging.getLogger("patient.ai_scheduling")
SCHEDULING_LLM_TIMEOUT_SECONDS = 8.0

_WEEKDAY_MAP = {
    "一": 0,
    "1": 0,
    "二": 1,
    "2": 1,
    "三": 2,
    "3": 2,
    "四": 3,
    "4": 3,
    "五": 4,
    "5": 4,
    "六": 5,
    "6": 5,
    "日": 6,
    "天": 6,
    "七": 6,
    "7": 6,
}
_DAY_PATTERNS = (
    "下下周一",
    "下下周二",
    "下下周三",
    "下下周四",
    "下下周五",
    "下下周六",
    "下下周日",
    "下下周天",
    "下周一",
    "下周二",
    "下周三",
    "下周四",
    "下周五",
    "下周六",
    "下周日",
    "下周天",
    "本周一",
    "本周二",
    "本周三",
    "本周四",
    "本周五",
    "本周六",
    "本周日",
    "本周天",
    "周一",
    "周二",
    "周三",
    "周四",
    "周五",
    "周六",
    "周日",
    "周天",
    "大后天",
    "后天",
    "明天",
    "今天",
)


def _extract_weekday_token(day_str: str) -> Optional[int]:
    for token, weekday in _WEEKDAY_MAP.items():
        if token in day_str:
            return weekday
    return None


def resolve_relative_date(day_str: str, base_date: date | None = None) -> date:
    """Resolve a Chinese relative date expression to a concrete date."""
    if base_date is None:
        base_date = date.today()

    normalized = str(day_str or "").strip()
    if not normalized:
        return base_date

    monday = base_date - timedelta(days=base_date.weekday())
    weekday = _extract_weekday_token(normalized)

    if "下下周" in normalized:
        return monday + timedelta(days=14 + (weekday or 0))

    if "下周" in normalized:
        return monday + timedelta(days=7 + (weekday or 0))

    if "本周" in normalized and weekday is not None:
        return monday + timedelta(days=weekday)

    if normalized.startswith("周") and weekday is not None:
        delta = (weekday - base_date.weekday()) % 7
        return base_date + timedelta(days=delta)

    if "大后天" in normalized:
        return base_date + timedelta(days=3)
    if "后天" in normalized:
        return base_date + timedelta(days=2)
    if "明天" in normalized:
        return base_date + timedelta(days=1)
    if "今天" in normalized:
        return base_date

    full_match = re.search(r"(\d{4})[-/](\d{1,2})[-/](\d{1,2})", normalized)
    if full_match:
        return date(int(full_match.group(1)), int(full_match.group(2)), int(full_match.group(3)))

    short_match = re.search(r"(\d{1,2})[-/](\d{1,2})", normalized)
    if short_match:
        return date(base_date.year, int(short_match.group(1)), int(short_match.group(2)))

    return base_date


def _find_first_day_expression(text: str, default: str) -> str:
    for pattern in _DAY_PATTERNS:
        if pattern in text:
            return pattern
    return default


def _extract_room_name(text: str) -> Optional[str]:
    match = re.search(
        r"([A-Za-z0-9一二三四五六七八九十甲乙丙丁妇儿内外神骨口耳眼皮泌消肿检验CTMR超声心电]+诊室)",
        text,
    )
    if match:
        return match.group(1)
    return None


def _build_rule_based_payload(prompt: str, *, today: date) -> dict[str, Any]:
    actions: list[dict[str, Any]] = []
    rule_parts: list[str] = []
    clauses = [part.strip() for part in re.split(r"[，；。并且另外]+", prompt) if part.strip()]

    cancel_after_clause = None
    time_threshold = None
    for clause in clauses:
        match = re.search(r"(\d+)\s*点(?:以后|之后)", clause)
        if match and any(keyword in clause for keyword in ("停诊", "取消", "别排", "不接")):
            cancel_after_clause = clause
            hour = int(match.group(1))
            if hour < 12 and "下午" in clause:
                hour += 12
            time_threshold = f"{hour:02d}:00"
            break

    if cancel_after_clause is not None and time_threshold:
        noon = "下午" if "下午" in cancel_after_clause else ("上午" if "上午" in cancel_after_clause else "下午")
        target_day = _find_first_day_expression(cancel_after_clause, "明天")
        target_date = resolve_relative_date(target_day, today)
        actions.append(
            {
                "action_type": "cancel_after_time",
                "target_date": target_date.strftime("%Y-%m-%d"),
                "noon": noon,
                "regist_quota": 0,
                "time_threshold": time_threshold,
            }
        )
        rule_parts.append(f"{target_day}{noon}{time_threshold}以后停诊")

    cancel_clause = None
    if cancel_after_clause is None:
        for clause in clauses:
            if any(keyword in clause for keyword in ("取消", "请假", "开会", "手术", "停诊")):
                cancel_clause = clause
                break

        if cancel_clause is not None:
            noon = "下午" if "下午" in cancel_clause else ("上午" if "上午" in cancel_clause else "下午")
            target_day = _find_first_day_expression(cancel_clause, "本周一")
            target_date = resolve_relative_date(target_day, today)
            actions.append(
                {
                    "action_type": "cancel",
                    "target_date": target_date.strftime("%Y-%m-%d"),
                    "noon": noon,
                    "regist_quota": 0,
                }
            )
            rule_parts.append(f"{target_day}{noon}因故取消排班")

    modify_clause = None
    for clause in clauses:
        if any(keyword in clause for keyword in ("限额", "号源", "额度", "调高", "调整", "增加", "新增")) or re.search(
            r"(\d+)\s*个",
            clause,
        ):
            modify_clause = clause
            break

    if modify_clause is not None:
        quota_match = re.search(r"(\d+)\s*个", modify_clause)
        quota = int(quota_match.group(1)) if quota_match else 45
        noon = "上午" if "上午" in modify_clause else ("下午" if "下午" in modify_clause else "上午")
        target_day = _find_first_day_expression(modify_clause, "下周一")
        target_date = resolve_relative_date(target_day, today)
        room_name = _extract_room_name(modify_clause)
        action_type = "add" if any(keyword in modify_clause for keyword in ("新增", "增加")) else "modify"
        actions.append(
            {
                "action_type": action_type,
                "target_date": target_date.strftime("%Y-%m-%d"),
                "noon": noon,
                "regist_quota": quota,
                "clinic_room_name": room_name,
            }
        )
        room_suffix = f"，诊室改为{room_name}" if room_name else ""
        rule_parts.append(f"{target_day}{noon}限额调整为{quota}个{room_suffix}")

    return {
        "actions": actions,
        "llm_text_rule": "；".join(rule_parts) + "。" if rule_parts else "排班规则未发生微调。",
    }


async def run_ai_scheduling(
    prompt: str,
    employee_uuid: str,
    api_key: str | None = None,
    api_base: str | None = None,
    model: str | None = None,
) -> dict[str, Any]:
    """Parse an AI scheduling request, preferring LLM and falling back to rules."""
    api_key = api_key or settings.LLM_API_KEY
    api_base = api_base or settings.LLM_API_BASE
    model = model or settings.LLM_MODEL
    started_at = start_ai_timer()

    today = date.today()
    today_str = today.strftime("%Y-%m-%d")
    weekday_str = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"][today.weekday()]

    if api_key and api_key.strip():
        logger.info("[AI Scheduling] Invoking real LLM Chat Completion API")
        try:
            system_prompt = (
                f"You are an expert hospital resource planning and scheduling AI. Today's date is {today_str} ({weekday_str}).\n"
                "Analyze the doctor's natural language request to modify their schedule and return a JSON object.\n"
                "You must output exactly this JSON schema:\n"
                "{\n"
                '  "actions": [\n'
                '    {\n'
                '      "action_type": "cancel or modify or add or cancel_after_time",\n'
                '      "target_date": "YYYY-MM-DD",\n'
                '      "noon": "上午 or 下午",\n'
                '      "regist_quota": 0,\n'
                '      "time_threshold": "HH:MM (required only for cancel_after_time, e.g. 15:00)",\n'
                '      "clinic_room_name": "真实诊室名称；仅在明确要求更换或指定诊室时提供，否则为 null"\n'
                '    }\n'
                '  ],\n'
                '  "llm_text_rule": "简短中文排班变更规则描述"\n'
                "}\n"
                "Guidelines:\n"
                "- If the action is cancel, set regist_quota to 0.\n"
                "- If the action is cancel_after_time, provide the exact time_threshold.\n"
                "- Calculate target dates relative to today's date correctly.\n"
                "- Return ONLY the raw JSON string without Markdown.\n"
            )
            data = await AIClient(api_key=api_key, api_base=api_base).chat_json(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt},
                ],
                temperature=0.1,
                timeout=SCHEDULING_LLM_TIMEOUT_SECONDS,
            )
            if isinstance(data, dict) and "actions" in data:
                payload = SchedulingParseData(**data).model_dump(mode="json")
                validation = AIResultValidator.validate_scheduling(payload)
                result = build_ai_result(
                    payload,
                    source=AISource.LLM,
                    model=model,
                    confidence=0.8,
                    **validation.as_result_kwargs(),
                )
                await record_ai_audit(
                    module_name="patient.scheduling",
                    input_text=prompt,
                    result=result,
                    context={"employee_uuid": employee_uuid},
                    latency_ms=elapsed_ms(started_at),
                )
                return result
        except Exception as exc:
            logger.error("[AI Scheduling] LLM invocation failed: %s. Falling back to rule parser.", exc)

    logger.info("[AI Scheduling] Running rule-based fallback parser")
    payload = SchedulingParseData(**_build_rule_based_payload(prompt, today=today)).model_dump(mode="json")
    validation = AIResultValidator.validate_scheduling(payload)
    result = build_ai_result(
        payload,
        source=AISource.RULE,
        model="rule-scheduling-parser",
        confidence=0.6 if payload["actions"] else 0.2,
        warnings=["using_rule_based_scheduling_parser", *validation.warnings],
        validated=validation.is_valid,
        validator_messages=list(validation.messages),
    )
    await record_ai_audit(
        module_name="patient.scheduling",
        input_text=prompt,
        result=result,
        context={"employee_uuid": employee_uuid},
        latency_ms=elapsed_ms(started_at),
    )
    return result
