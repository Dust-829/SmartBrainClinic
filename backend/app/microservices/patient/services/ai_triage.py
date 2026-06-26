
"""
AI 智能分诊 - 多轮对话引擎
支持多轮对话收集患者信息，逐步判断科室。
返回中包含 dept_determined 标志，便于前端判断是否已得出科室。
"""

import logging
from typing import Dict, Any, List
from app.common.ai_audit import elapsed_ms, record_ai_audit, start_ai_timer
from app.common.ai_client import AIClient
from app.common.ai_schema import AISource, TriageResultData, build_ai_result
from app.common.ai_validator import AIResultValidator

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

SYSTEM_PROMPT = (
    "你是一位专业的医院AI分诊助手。你的唯一职责是通过与患者对话，引导并收集关键症状信息，最终判断出应该前往哪个科室就诊。\n\n"
    "【你的行为准则】\n"
    "1. 如果患者的描述信息不足以判断科室（比如只说了'你好'、'不舒服'等模糊表述），你必须礼貌地追问，引导患者描述具体症状、持续时间、部位等关键信息。\n"
    "2. 当你根据对话内容有足够的信心判断出科室时，在回复中标记科室，但不要擅自结束对话——患者可能还想继续补充信息。\n"
    "3. 你只负责分诊引导，禁止给出任何诊断结论、用药建议、检查建议或治疗方案。\n"
    "4. 在对话过程中，尽量自然地引导患者提及：主要症状、持续时间、过敏史、既往病史。但不要一次问太多，每次1-2个问题即可。\n\n"
    "【输出格式要求】\n"
    "你必须严格输出一个JSON对象，不要包含任何markdown代码块包裹，格式如下：\n"
    "{\n"
    '  "reply": "你要对患者说的话（中文）",\n'
    '  "dept_determined": false或true,\n'
    '  "recommended_dept_code": null或科室代码字符串,\n'
    '  "symptom_summary": "从对话中提炼的核心症状摘要（用于后续医生推荐的语义匹配），如果信息不足则填null",\n'
    '  "gender_preference": "根据症状或患者表述判断的医生性别倾向，只能填 男、女 或 不限，默认不限"\n'
    "}\n\n"
    "其中 recommended_dept_code 只能是以下值之一：SJWK(神经外科), XNK(心内科), GK(骨科), EK(儿科), FCK(妇产科)\n"
    "当你尚未判断出科室时，dept_determined=false，recommended_dept_code=null。\n"
    "当你判断出科室后，dept_determined=true，recommended_dept_code填对应的代码。\n"
    "一旦判断出科室，后续对话中仍然保持dept_determined=true和对应的科室代码。\n"
    "symptom_summary 应当随着每轮对话不断完善，将已知的症状、持续时间、部位等信息浓缩成一句话。\n"
    "gender_preference 的判断规则：涉及妇产科时填女，其他情况默认填不限，除非患者明确表达了偏好。\n\n"
    "请只返回原始JSON字符串，不要有任何额外文字。"
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
    from app.microservices.patient.config import PatientSettings
    started_at = start_ai_timer()
    settings = PatientSettings()
    api_key = api_key or settings.LLM_API_KEY
    api_base = api_base or settings.LLM_API_BASE
    model = model or getattr(settings, "LLM_MODEL", "deepseek-ai/DeepSeek-V4-Flash")

    # 1. 尝试真实大模型
    if api_key and api_key.strip():
        logger.info("🤖 [AI Triage] Invoking real LLM for multi-turn triage...")
        try:
            # 构造完整的消息列表：system + 历史对话
            full_messages = [{"role": "system", "content": SYSTEM_PROMPT}]
            for msg in messages:
                full_messages.append({
                    "role": msg.get("role", "user"),
                    "content": msg.get("content", "")
                })

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
                validation = AIResultValidator.validate_triage(
                    data,
                    allowed_dept_codes=DEPT_MAP.keys(),
                )

                logger.info(f"✅ [AI Triage] LLM response: {data}")
                result = build_ai_result(
                    data,
                    source=AISource.LLM,
                    model=model,
                    confidence=0.85 if data.get("dept_determined") else 0.45,
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
    validation = AIResultValidator.validate_triage(data, allowed_dept_codes=DEPT_MAP.keys())
    result = build_ai_result(
        data,
        source=AISource.MOCK,
        model="mock-triage",
        confidence=0.65 if data.get("dept_determined") else 0.35,
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
