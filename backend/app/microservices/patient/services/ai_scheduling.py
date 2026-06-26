"""
AI 智能排班解析与执行引擎
"""

import logging
import re
from datetime import date, timedelta
from typing import Dict, Any
from ..config import settings
from app.common.ai_audit import elapsed_ms, record_ai_audit, start_ai_timer
from app.common.ai_client import AIClient
from app.common.ai_schema import AISource, SchedulingParseData, build_ai_result
from app.common.ai_validator import AIResultValidator

logger = logging.getLogger("patient.ai_scheduling")

def resolve_relative_date(day_str: str, base_date: date = None) -> date:
    """
    根据给定的星期词汇（如 "周三", "本周三", "下周一"）和基准日期计算具体日期。
    """
    if base_date is None:
        base_date = date.today()
        
    # 获取本周周一的日期
    monday = base_date - timedelta(days=base_date.weekday())
    
    # 星期映射
    week_map = {
        "一": 0, "1": 0,
        "二": 1, "2": 1,
        "三": 2, "3": 2,
        "四": 3, "4": 3,
        "五": 4, "5": 4,
        "六": 5, "6": 5,
        "日": 6, "天": 6, "7": 6
    }
    
    # 处理 "下周" 开头
    if "下周" in day_str:
        for k, v in week_map.items():
            if k in day_str:
                return monday + timedelta(days=7 + v)
        return monday + timedelta(days=7) # 默认下周一
        
    # 处理 "下下周"
    if "下下周" in day_str:
        for k, v in week_map.items():
            if k in day_str:
                return monday + timedelta(days=14 + v)
        return monday + timedelta(days=14)
        
    # 处理 "本周" 或 "周"
    for k, v in week_map.items():
        if k in day_str:
            return monday + timedelta(days=v)
            
    # 处理 "今天", "明天", "后天"
    if "大后天" in day_str:
        return base_date + timedelta(days=3)
    if "后天" in day_str:
        return base_date + timedelta(days=2)
    if "明天" in day_str:
        return base_date + timedelta(days=1)
    if "今天" in day_str:
        return base_date
            
    # 如果没匹配到，看是否有具体的日期格式如 2026-05-22
    match = re.search(r"(\d{4})[-/](\d{1,2})[-/](\d{1,2})", day_str)
    if match:
        return date(int(match.group(1)), int(match.group(2)), int(match.group(3)))
        
    match_short = re.search(r"(\d{1,2})[-/](\d{1,2})", day_str)
    if match_short:
        return date(base_date.year, int(match_short.group(1)), int(match_short.group(2)))
        
    return base_date

async def run_ai_scheduling(
    prompt: str,
    employee_uuid: str,
    api_key: str = None,
    api_base: str = None,
    model: str = None,
) -> Dict[str, Any]:
    """
    解析排班微调请求。
    如果配置了 api_key，则发起真实的 OpenAI 格式 HTTP 请求；
    否则，或者当 API 请求失败时，自动降级至内置的高保真 Mock 匹配引擎。
    """
    api_key = api_key or settings.LLM_API_KEY
    api_base = api_base or settings.LLM_API_BASE
    model = model or settings.LLM_MODEL
    started_at = start_ai_timer()
    
    today = date.today()
    today_str = today.strftime("%Y-%m-%d")
    weekday_str = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"][today.weekday()]

    if api_key and api_key.strip():
        logger.info("🤖 [AI Scheduling] Invoking real LLM Chat Completion API...")
        try:
            system_prompt = (
                f"You are an expert hospital resource planning and scheduling AI. Today's date is {today_str} ({weekday_str}).\n"
                "Analyze the doctor's natural language request to modify their schedule and return a JSON object.\n"
                "You must output exactly this JSON schema:\n"
                "{\n"
                '  "actions": [\n'
                '    {\n'
                '      "action_type": "cancel 或 modify 或 add 或 cancel_after_time",\n'
                '      "target_date": "YYYY-MM-DD",\n'
                '      "noon": "上午 或 下午",\n'
                '      "regist_quota": 0,\n'
                '      "time_threshold": "HH:MM (仅当 action_type 为 cancel_after_time 时使用，如 15:00)",\n'
                '      "clinic_room_name": "真实的诊室名称（例如：妇科一诊室），请务必去掉楼层、楼栋等位置前缀，仅在被要求更换或指定诊室时提取，否则返回 null"\n'
                '    }\n'
                '  ],\n'
                '  "llm_text_rule": "简短的中文排班变更规则描述"\n'
                "}\n"
                "Guidelines:\n"
                "- If the action is cancel, set regist_quota to 0.\n"
                "- If the action is cancel_after_time, provide the exact time_threshold (e.g. 15:00).\n"
                "- Calculate target dates relative to today's date correctly.\n"
                "- Return ONLY the raw JSON string without any Markdown code blocks or wrapping."
            )
            
            data = await AIClient(api_key=api_key, api_base=api_base).chat_json(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1,
                timeout=60.0,
            )
            if isinstance(data, dict) and "actions" in data:
                data = SchedulingParseData(**data).model_dump(mode="json")
                validation = AIResultValidator.validate_scheduling(data)
                logger.info(f"✅ [AI Scheduling] Real LLM parsing succeeded: {data}")
                result = build_ai_result(
                    data,
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
        except Exception as e:
            logger.error(f"⚠️ [AI Scheduling] Real LLM invocation failed: {e}. Falling back to offline engine...")

    # 2. 高保真内置 Mock 匹配与日期解析引擎
    logger.info("🔌 [AI Scheduling] Running offline High-Fidelity Mock AI Scheduling Engine...")
    
    actions = []
    llm_text_rule_parts = []
    
    # 将 prompt 拆分为可能包含不同指令的子句
    clauses = re.split(r"[，；并且另外]", prompt)
    
    day_patterns = ["下周三", "下周二", "下周一", "下周四", "下周五", "本周三", "本周一", "本周二", "本周四", "本周五", "周三", "周一", "周二", "周四", "周五", "周六", "周日", "大后天", "后天", "明天", "今天"]

    # 匹配推掉某个时间点以后的号 (例如 "推掉明天下午3点以后的号")
    cancel_after_clause = None
    time_threshold = None
    for clause in clauses:
        match = re.search(r"(\d+)点以后", clause)
        if match and any(k in clause for k in ["推", "取消", "别排", "不接"]):
            cancel_after_clause = clause
            hour = int(match.group(1))
            if hour < 12 and "下午" in clause:
                hour += 12 # 3点以后 -> 15:00
            time_threshold = f"{hour:02d}:00"
            break
            
    if cancel_after_clause is not None:
        noon = "下午" if "下午" in cancel_after_clause else ("上午" if "上午" in cancel_after_clause else "下午")
        target_day_str = "明天"
        for day in day_patterns:
            if day in cancel_after_clause:
                target_day_str = day
                break
        target_date = resolve_relative_date(target_day_str, today)
        actions.append({
            "action_type": "cancel_after_time",
            "target_date": target_date.strftime("%Y-%m-%d"),
            "noon": noon,
            "regist_quota": 0,
            "time_threshold": time_threshold
        })
        llm_text_rule_parts.append(f"{target_day_str}{noon}{time_threshold}以后停诊")
        
    # 匹配取消排班 (例如 "取消周三下午")
    cancel_clause = None
    if not cancel_after_clause:
        for clause in clauses:
            if any(k in clause for k in ["取消", "请假", "开会", "手术"]):
                cancel_clause = clause
                break
                
        if cancel_clause is not None:
            noon = "下午" if "下午" in cancel_clause else ("上午" if "上午" in cancel_clause else "下午")
            target_day_str = "本周三"
            for day in day_patterns:
                if day in cancel_clause:
                    target_day_str = day
                    break
            
            target_date = resolve_relative_date(target_day_str, today)
            actions.append({
                "action_type": "cancel",
                "target_date": target_date.strftime("%Y-%m-%d"),
                "noon": noon,
                "regist_quota": 0
            })
            llm_text_rule_parts.append(f"{target_day_str}{noon}因故取消排班")
        
    # 匹配新增/修改排班 (例如 "下周一上午的限额临时调高为45个")
    modify_clause = None
    for clause in clauses:
        if any(k in clause for k in ["限额", "号源", "额度", "调高", "调整"]) or re.search(r"\d+\s*个", clause):
            modify_clause = clause
            break
            
    if modify_clause is not None:
        quota_match = re.search(r"(\d+)\s*个", modify_clause)
        quota = int(quota_match.group(1)) if quota_match else 45
        
        noon = "上午" if "上午" in modify_clause else ("下午" if "下午" in modify_clause else "上午")
        target_day_str = "明天" if "明天" in modify_clause else "下周一"
        day_patterns = ["下周三", "下周二", "下周一", "下周四", "下周五", "本周三", "本周一", "本周二", "本周四", "本周五", "周三", "周一", "周二", "周四", "周五", "周六", "周日", "大后天", "后天", "明天", "今天"]
        for day in day_patterns:
            if day in modify_clause:
                target_day_str = day
                break
                
        target_date = resolve_relative_date(target_day_str, today)
        
        # 提取诊室名称（模拟）
        room_name = None
        room_match = re.search(r"到(.+?诊室)", modify_clause)
        if room_match:
            room_name = room_match.group(1)
            
        actions.append({
            "action_type": "modify",
            "target_date": target_date.strftime("%Y-%m-%d"),
            "noon": noon,
            "regist_quota": quota,
            "clinic_room_name": room_name
        })
        llm_text_rule_parts.append(f"{target_day_str}{noon}限额调整为{quota}个" + (f"，诊室改为{room_name}" if room_name else ""))
        
    rule_desc = "；".join(llm_text_rule_parts) + "。" if llm_text_rule_parts else "排班规则未发生微调。"
    
    data = {
        "actions": actions,
        "llm_text_rule": rule_desc
    }
    data = SchedulingParseData(**data).model_dump(mode="json")
    validation = AIResultValidator.validate_scheduling(data)
    result = build_ai_result(
        data,
        source=AISource.RULE,
        model="rule-scheduling-parser",
        confidence=0.6 if actions else 0.2,
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
